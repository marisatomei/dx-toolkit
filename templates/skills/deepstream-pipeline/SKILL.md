---
name: deepstream-pipeline
description: 'Design and build an NVIDIA DeepStream video analytics pipeline using the pyservicemaker Python API (DS 9.0+). Use when starting a new pipeline, integrating new sources or models, adding tracking and message broker output, or troubleshooting an existing pipeline.'
---

# DeepStream Pipeline

## When to Use

- Starting a new DeepStream video analytics application
- Adding multi-stream sources to an existing pipeline
- Integrating a new inference model (detection, classification, segmentation)
- Adding object tracking or downstream message broker output
- Troubleshooting pipeline stalls, low throughput, or metadata errors

## Procedure

### 1. Clarify requirements

Answer these before writing any code:

- **Input sources**: RTSP streams, local files, USB cameras, synthetic? How many streams?
- **Inference**: What model(s)? Object detection only, or classification/segmentation too? Cascaded (PGIE + SGIE)?
- **Tracking**: Required? Which tracker fits the scene — NvDCF (accuracy) or IOU (speed)?
- **Output**: On-screen display, Kafka/MQTT message broker, file sink, custom sink?
- **Headless**: Server/cloud deployment (no display) or edge with HDMI output?
- **Dynamic sources**: Does the pipeline need runtime source add/remove via REST API?
- **Target hardware**: x86 + NVIDIA GPU, or Jetson (ARM64)?

### 2. Choose the API

| API                             | When to use                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------------ |
| **Flow API** (declarative)      | Static pipeline, configuration-driven, minimal Python boilerplate                    |
| **Pipeline API** (programmatic) | Dynamic element manipulation, conditional pipeline topology, tight GStreamer control |

Flow API for most cases:

```python
from pyservicemaker import Pipeline, Node, App

pipeline = Pipeline("my-pipeline")
src  = Node("nvurisrcbin", "src0", {"uri": "rtsp://cam0/stream", "gpu-id": 0})
mux  = Node("nvstreammux", "mux", {"batch-size": 1, "width": 1920, "height": 1080,
                                    "batched-push-timeout": 40000})
gie  = Node("nvinfer", "pgie", {"config-file-path": "config_infer_primary.txt"})
sink = Node("fakesink", "sink", {"sync": False})

pipeline.add([src, mux, gie, sink])
pipeline.link(src, mux).link(mux, gie).link(gie, sink)

App().add(pipeline).run()
```

### 3. Configure sources (nvurisrcbin / nvstreammux)

```ini
# For RTSP sources: set live-source=1 in nvstreammux
[streammux]
batch-size=4
width=1920
height=1080
batched-push-timeout=40000
live-source=1
```

For multiple RTSP streams, add multiple `nvurisrcbin` elements all linked to the same `nvstreammux`. Number of sources must match or be less than `batch-size`.

For file sources, `live-source=0` and `batched-push-timeout` can be lower (e.g., `4000`).

### 4. Configure primary inference (nvinfer)

```ini
# config_infer_primary.txt
[property]
gpu-id=0
onnx-file=model.onnx
model-engine-file=model_b4_gpu0_fp16.engine
labelfile-path=labels.txt
batch-size=4
network-mode=2               # 2=FP16
num-detected-classes=80
interval=0
gie-unique-id=1
network-type=0               # 0=Detector

[class-attrs-all]
pre-cluster-threshold=0.3
nms-iou-threshold=0.5
```

For cascaded inference, add a second `nvinfer` element with:

```ini
gie-unique-id=2
operate-on-gie-id=1
operate-on-class-ids=0       # Run SGIE only on class 0 from PGIE
network-type=1               # 1=Classifier
```

### 5. Add tracking (nvtracker)

```ini
# config_tracker.yml
[tracker]
enable=1
tracker-width=640
tracker-height=384
ll-lib-file=/opt/nvidia/deepstream/deepstream/lib/libnvds_nvdcf.so
ll-config-file=config_tracker_NvDCF_accuracy.yml
display-tracking-id=1
```

Add element after PGIE:

```python
tracker = Node("nvtracker", "tracker", {"ll-lib-file": "...", "ll-config-file": "..."})
pipeline.link(gie, tracker).link(tracker, ...)
```

### 6. Add metadata probe (optional custom logic)

```python
def on_frame(pad, info, user_data):
    buf = info.get_buffer()
    batch_meta = pyservicemaker.gst_buffer_get_nvds_batch_meta(hash(buf))
    if batch_meta is None:
        return Gst.PadProbeReturn.OK
    for frame_meta in NvDsBatchMeta.get_frame_meta_list(batch_meta):
        for obj_meta in NvDsFrameMeta.get_obj_meta_list(frame_meta):
            # Filter, annotate, or copy to application state
            pass
    return Gst.PadProbeReturn.OK

gie_src_pad = gie.element.get_static_pad("src")
gie_src_pad.add_probe(Gst.PadProbeType.BUFFER, on_frame, None)
```

### 7. Add message broker (nvmsgconv + nvmsgbroker)

```python
conv   = Node("nvmsgconv", "msgconv", {
    "config": "msgconv_config.txt",
    "payload-type": 0            # 0=NVDS_PAYLOAD_DEEPSTREAM
})
broker = Node("nvmsgbroker", "msgbroker", {
    "proto-lib": "/opt/nvidia/deepstream/deepstream/lib/libnvds_kafka_proto.so",
    "conn-str": "localhost;9092",
    "topic": "ds-events"
})
pipeline.link(tracker, conv).link(conv, broker)
```

### 8. Handle headless vs display mode

Always implement both modes:

```python
headless = os.getenv("DS_HEADLESS", "1") == "1"

if headless:
    sink = Node("fakesink", "sink", {"sync": False})
else:
    tiler  = Node("nvmultistreamtiler", "tiler", {"rows": 2, "columns": 2,
                                                   "width": 1280, "height": 720})
    osd    = Node("nvdsosd", "osd", {"process-mode": 0})
    conv   = Node("nvvideoconvert", "conv", {})
    sink   = Node("nveglglessink", "sink", {"sync": False})
    pipeline.add([tiler, osd, conv, sink])
```

### 9. Smoke test the pipeline

Before deploying:

```bash
# Test pipeline element by element with gst-launch-1.0
gst-launch-1.0 -e \
  nvurisrcbin uri=rtsp://cam0/stream ! \
  nvstreammux name=mux batch-size=1 width=1920 height=1080 ! \
  nvinfer config-file-path=config_infer_primary.txt ! \
  fakesink sync=false

# Check for:
# - No "no element" errors (plugins are installed)
# - No CAPS negotiation errors
# - Frame rate reported in output (not 0 fps)
# - No tensor memory errors from nvinfer
```

For RTSP, always test the stream is reachable: `ffprobe rtsp://cam0/stream -v error`.

## Red Flags

- `batched-push-timeout` not set for live RTSP sources → pipeline stalls on source disconnect
- `live-source=0` with RTSP → incorrect timestamping, tracker drift
- `batch-size` in config doesn't match actual connected sources → inference every batch is partial
- Missing `fakesink` in headless mode → `nveglglessink` crashes without display
- Probe callback returning `GST_PAD_PROBE_DROP` when it should return `GST_PAD_PROBE_OK` → missing frames

## Verification

- [ ] Pipeline runs for 60 seconds without crash or stall
- [ ] Detected objects visible in OSD (or logged in headless mode)
- [ ] Object IDs incrementing correctly (tracker working)
- [ ] Kafka/MQTT topic receiving messages (if broker configured)
- [ ] GPU memory stable (run `nvidia-smi dmon -s m` during test)
- [ ] CPU usage < 20% per stream (GPU doing the heavy lifting)
