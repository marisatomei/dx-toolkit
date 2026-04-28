---
name: deepstream-plugin
description: 'Write a custom GStreamer plugin or customize the nvmsgconv schema for NVIDIA DeepStream. Use when you need a custom JSON payload schema, a custom GStreamer source/transform/sink plugin, or a fully custom nvds_msg2p implementation. Covers C++ scaffolding, CMake build, and gst-inspect testing.'
---

# DeepStream Plugin

## When to Use

- Customizing the nvmsgconv JSON payload schema for a custom analytics format
- Writing a custom GStreamer source plugin (proprietary input format, hardware interface)
- Writing a custom GStreamer transform plugin (metadata enrichment, ROI filtering, custom analytics)
- Writing a fully custom `nvds_msg2p` shared library to replace nvmsgconv's built-in payloads
- Integrating a third-party C library as a GStreamer element

## Procedure

### 1. Identify the plugin type

| Task                                            | What to do                                           |
| ----------------------------------------------- | ---------------------------------------------------- |
| Change JSON field names/structure               | Modify `nvmsgconv.cpp` or `eventmsg_payload.cpp`     |
| Add fields from custom NvDsEventMsgMeta         | Modify `eventmsg_payload.cpp`                        |
| Skip NvDsEventMsgMeta, read from NvDsObjectMeta | Set `msg2p-newapi=true`, modify `dsmeta_payload.cpp` |
| Fully custom payload schema                     | Implement `nvds_msg2p` interface in a new .so        |
| Custom input source                             | New `GstBaseSrc` subclass                            |
| Custom metadata transform                       | New `GstBaseTransform` subclass                      |

### 2. Set up the project structure

```
myplugin/
├── CMakeLists.txt
├── src/
│   ├── gstmyplugin.h
│   ├── gstmyplugin.cpp
│   └── plugin.cpp          # GST_PLUGIN_DEFINE entry point
└── test/
    └── test_gstmyplugin.sh
```

For nvmsgconv customization:

```
custom_nvmsgconv/
├── CMakeLists.txt
├── nvmsgconv.cpp           # copy from DS sources, then modify
├── eventmsg_payload.cpp    # copy from DS sources, then modify
├── dsmeta_payload.cpp      # copy from DS sources, then modify
└── nvmsgconv.h
```

### 3. Scaffold a GstBaseTransform plugin

```cpp
// gstmyplugin.h
#pragma once
#include <gst/base/gstbasetransform.h>
#include "nvds_meta.h"

G_BEGIN_DECLS

#define GST_TYPE_MY_PLUGIN (gst_my_plugin_get_type())
G_DECLARE_FINAL_TYPE(GstMyPlugin, gst_my_plugin, GST, MY_PLUGIN, GstBaseTransform)

struct _GstMyPlugin {
    GstBaseTransform parent;
    gfloat threshold;
    GMutex lock;
};

G_END_DECLS
```

```cpp
// gstmyplugin.cpp
#include "gstmyplugin.h"

GST_DEBUG_CATEGORY_STATIC(gst_my_plugin_debug);
#define GST_CAT_DEFAULT gst_my_plugin_debug

#define DEFAULT_THRESHOLD 0.5f

enum { PROP_0, PROP_THRESHOLD };

static GstStaticPadTemplate sink_tmpl = GST_STATIC_PAD_TEMPLATE("sink",
    GST_PAD_SINK, GST_PAD_ALWAYS,
    GST_STATIC_CAPS("video/x-raw(memory:NVMM), format=(string){NV12,RGBA}"));

static GstStaticPadTemplate src_tmpl = GST_STATIC_PAD_TEMPLATE("src",
    GST_PAD_SRC, GST_PAD_ALWAYS,
    GST_STATIC_CAPS("video/x-raw(memory:NVMM), format=(string){NV12,RGBA}"));

G_DEFINE_TYPE(GstMyPlugin, gst_my_plugin, GST_TYPE_BASE_TRANSFORM);

static void gst_my_plugin_set_property(GObject *obj, guint id, const GValue *v, GParamSpec *ps) {
    GstMyPlugin *self = GST_MY_PLUGIN(obj);
    switch (id) {
        case PROP_THRESHOLD:
            g_mutex_lock(&self->lock);
            self->threshold = g_value_get_float(v);
            g_mutex_unlock(&self->lock);
            break;
        default: G_OBJECT_WARN_INVALID_PROPERTY_ID(obj, id, ps);
    }
}

static GstFlowReturn gst_my_plugin_transform_ip(GstBaseTransform *trans, GstBuffer *buf) {
    GstMyPlugin *self = GST_MY_PLUGIN(trans);
    NvDsBatchMeta *batch_meta = gst_buffer_get_nvds_batch_meta(buf);
    if (!batch_meta) return GST_FLOW_OK;

    for (NvDsFrameMetaList *fl = batch_meta->frame_meta_list; fl; fl = fl->next) {
        NvDsFrameMeta *frame = (NvDsFrameMeta *) fl->data;
        for (NvDsObjectMetaList *ol = frame->obj_meta_list; ol; ol = ol->next) {
            NvDsObjectMeta *obj = (NvDsObjectMeta *) ol->data;
            if (obj->confidence < self->threshold) {
                // filter low-confidence objects
                nvds_remove_obj_meta_from_frame(frame, obj);
            }
        }
    }
    return GST_FLOW_OK;
}

static void gst_my_plugin_class_init(GstMyPluginClass *klass) {
    GObjectClass *gc = G_OBJECT_CLASS(klass);
    GstElementClass *ec = GST_ELEMENT_CLASS(klass);
    GstBaseTransformClass *bc = GST_BASE_TRANSFORM_CLASS(klass);

    gc->set_property = gst_my_plugin_set_property;
    g_object_class_install_property(gc, PROP_THRESHOLD,
        g_param_spec_float("threshold", "Confidence Threshold",
            "Minimum confidence to keep detection", 0.0f, 1.0f, DEFAULT_THRESHOLD,
            (GParamFlags)(G_PARAM_READWRITE | GST_PARAM_MUTABLE_PLAYING | G_PARAM_STATIC_STRINGS)));

    gst_element_class_add_static_pad_template(ec, &sink_tmpl);
    gst_element_class_add_static_pad_template(ec, &src_tmpl);
    gst_element_class_set_static_metadata(ec,
        "My Custom Filter", "Filter/Video",
        "Custom DeepStream metadata filter", "Your Name <email>");

    bc->transform_ip = gst_my_plugin_transform_ip;
    bc->transform_ip_on_passthrough = TRUE;
}

static void gst_my_plugin_init(GstMyPlugin *self) {
    g_mutex_init(&self->lock);
    self->threshold = DEFAULT_THRESHOLD;
    gst_base_transform_set_in_place(GST_BASE_TRANSFORM(self), TRUE);
}
```

```cpp
// plugin.cpp — entry point
#include "gstmyplugin.h"
GST_DEBUG_CATEGORY(gst_my_plugin_debug);

static gboolean plugin_init(GstPlugin *plugin) {
    GST_DEBUG_CATEGORY_INIT(gst_my_plugin_debug, "myplugin", 0, "My Plugin");
    return gst_element_register(plugin, "myplugin", GST_RANK_NONE, GST_TYPE_MY_PLUGIN);
}

GST_PLUGIN_DEFINE(GST_VERSION_MAJOR, GST_VERSION_MINOR, myplugin,
    "Custom DeepStream plugin", plugin_init, "1.0.0", "MIT", "myplugin", "https://example.com")
```

### 4. CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.12)
project(myplugin LANGUAGES CXX)

set(CUDA_VER "12.4" CACHE STRING "CUDA version")
set(DS_ROOT "/opt/nvidia/deepstream/deepstream" CACHE PATH "DeepStream install root")

find_package(PkgConfig REQUIRED)
pkg_check_modules(GST REQUIRED gstreamer-1.0>=1.14)
pkg_check_modules(GST_BASE REQUIRED gstreamer-base-1.0>=1.14)

include_directories(
    ${DS_ROOT}/sources/includes
    /usr/local/cuda-${CUDA_VER}/include
    ${GST_INCLUDE_DIRS}
)

add_library(gstmyplugin SHARED
    src/gstmyplugin.cpp
    src/plugin.cpp
)
target_link_libraries(gstmyplugin PRIVATE ${GST_LIBRARIES} ${GST_BASE_LIBRARIES})
set_target_properties(gstmyplugin PROPERTIES PREFIX "")  # GStreamer plugins have no lib prefix

install(TARGETS gstmyplugin DESTINATION ${DS_ROOT}/lib/gst-plugins/)
```

### 5. Customize nvmsgconv payload

For schema changes without a full custom library:

**a. Enable newapi mode** in `msgconv_config.txt`:

```ini
[sensor0]
enable=1
type=1
id=SENSOR-001
desc=Camera 0
msg2p-newapi=true           # read from NvDsFrameMeta directly
```

**b. Modify `dsmeta_payload.cpp`** (newapi path) to add custom fields:

```cpp
// In generate_dsmeta_message(), inside the object loop:
Json::Value obj_json;
obj_json["object_id"] = (Json::UInt64) obj->object_id;
obj_json["class"]     = obj->obj_label;
obj_json["conf"]      = obj->confidence;
// Custom field from tracker misc_obj_info:
obj_json["speed_mps"] = obj->misc_obj_info[0];
objects.append(obj_json);
```

**c. Rebuild and install**:

```bash
mkdir build && cd build
cmake .. -DDS_ROOT=/opt/nvidia/deepstream/deepstream
make -j$(nproc)
sudo make install
```

### 6. Fully custom nvds_msg2p library

```c
// mymsgconv.c
#include "nvmsgbroker.h"

void *nvds_msg2p_ctx_create(const char *file, NvDsPayloadType type) {
    // parse config file, return context
    return malloc(sizeof(MyCtx));
}

void nvds_msg2p_ctx_destroy(void *ctx) { free(ctx); }

NvDsPayload* nvds_msg2p(void *ctx, const NvDsEvent *events, guint event_size) {
    // build JSON/Protobuf/Avro from events
    // allocate and return NvDsPayload
}

NvDsPayload** nvds_msg2p_release(void *ctx, NvDsPayload *payload) {
    free(payload->payload);
    free(payload);
    return NULL;
}
```

Configure: `nvmsgconv custom-lib-path=/path/to/libmymsgconv.so`.

### 7. Test the plugin

```bash
# Step 1: verify the plugin registers correctly
GST_PLUGIN_PATH=/build gst-inspect-1.0 myplugin
# Expected: element description, pad templates, and properties listed

# Step 2: smoke test in a minimal pipeline
GST_PLUGIN_PATH=/build gst-launch-1.0 -e \
  videotestsrc num-buffers=50 ! \
  nvvideoconvert ! "video/x-raw(memory:NVMM),format=NV12" ! \
  myplugin threshold=0.4 ! \
  fakesink sync=false
# Expected: runs to EOS with no errors

# Step 3: test with real DeepStream pipeline
GST_PLUGIN_PATH=/build gst-launch-1.0 -e \
  nvurisrcbin uri=file:///data/test.mp4 ! \
  nvstreammux batch-size=1 width=1920 height=1080 name=mux ! \
  nvinfer config-file-path=config_infer_primary.txt ! \
  myplugin threshold=0.5 ! \
  fakesink sync=false
```

## Red Flags

- `gst-inspect-1.0` fails to load the .so → missing GStreamer dependencies or ABI mismatch
- `transform_ip` returns `GST_FLOW_ERROR` for valid frames → causes upstream EOS, pipeline terminates
- `nvds_msg2p_release` not implemented → memory leak on every message
- Setting plugin properties after `PLAYING` without `GST_PARAM_MUTABLE_PLAYING` flag → property value silently ignored
- Forgetting `g_mutex_init` for a mutex field → undefined behavior (not NULL in C)

## Verification

- [ ] `gst-inspect-1.0` shows all registered properties with correct types and defaults
- [ ] Minimal `videotestsrc` pipeline runs to EOS cleanly
- [ ] Full DS pipeline with the plugin runs 60 seconds without crash
- [ ] Valgrind shows no memory leaks from plugin code (CPU-only path)
- [ ] Custom payload received and parseable on Kafka/MQTT consumer
- [ ] Plugin properties can be changed at runtime (if `MUTABLE_PLAYING` is set)
