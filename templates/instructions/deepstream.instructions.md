---
applyTo: '**/*.py, **/*.cpp, **/*.h, **/*.cu, **/*.yaml, **/*.yml, **/*.txt'
description: 'NVIDIA DeepStream SDK coding standards. Covers pyservicemaker Python API conventions, GStreamer plugin patterns, NvDs metadata access rules, CUDA buffer safety, nvinfer config best practices, and CMake build patterns for DeepStream 9.0+.'
---

# DeepStream Coding Standards

## Python (pyservicemaker)

- **Use pyservicemaker for all new DS 9.0+ Python code.** The `pyds` bindings are deprecated since DS 9.0 and must not be used in new code.
- Prefer the **Flow API** for static pipelines (declarative, less boilerplate). Use the **Pipeline API** only when you need programmatic element manipulation at runtime.
- Import pattern:
  ```python
  from pyservicemaker import Pipeline, Node, App, NvDsBatchMeta, NvDsFrameMeta, NvDsObjectMeta
  ```
- Never import from `pyds` in new files. If porting old code, migrate all `pyds.` calls to the pyservicemaker equivalents.

## Metadata access

- Access `NvDsBatchMeta` / `NvDsFrameMeta` / `NvDsObjectMeta` **only inside pad probe callbacks** registered with `add_probe()`. Never cache raw pointers across frame boundaries — they are invalidated after the probe returns.
- Always check for `None` / `NULL` before dereferencing metadata pointers:
  ```python
  if batch_meta is None:
      return Gst.PadProbeReturn.OK
  ```
- For C++ probes, acquire any GLib mutex before modifying shared metadata structures:
  ```cpp
  NvDsMetaLock(batch_meta);
  // modify metadata
  NvDsMetaUnlock(batch_meta);
  ```

## GPU buffer access

- Use `NvBufSurfaceMap` / `NvBufSurfaceUnMap` for CPU access to GPU (NVMM) buffers. Never call `cudaMemcpy` directly on mapped DS buffers.
- Always unmap in the same scope — use RAII or finally blocks:
  ```python
  NvBufSurfaceMap(surface, -1, -1, NVBUF_MAP_READ)
  try:
      # access surface.surfaceList[idx].mappedAddr
  finally:
      NvBufSurfaceUnmap(surface, -1, -1)
  ```
- Do not hold GPU buffer maps across `await` suspension points or across probe return boundaries.

## Pipeline properties

- Set all GStreamer element properties **before** transitioning the pipeline to `PLAYING` state. Setting properties after `PLAYING` is element-specific and may be silently ignored.
- For runtime property changes (e.g., `nvdsinfer` `interval`), explicitly verify the element supports dynamic updates — check the element's `GST_PARAM_MUTABLE_PLAYING` flag.

## nvinfer config files

- Use relative paths or environment variable substitution — never hardcode absolute `/home/user/...` paths in config files.
- Always set `model-engine-file` to a versioned filename that encodes batch size, precision, and GPU generation:
  ```
  model-engine-file=model_b4_gpu0_fp16_sm86.engine
  ```
- Delete stale `.engine` files when changing `batch-size`, `network-mode`, `gpu-id`, TensorRT version, or CUDA version.
- Each GIE must have a unique `gie-unique-id`. Duplicate IDs cause silent inference skips.

## C++ plugin development

- Use `GST_DEBUG_CATEGORY` for all logging. Never use `printf`, `std::cout`, or `fprintf(stderr)` in production plugin code:
  ```cpp
  GST_DEBUG_OBJECT(self, "Processing frame %u", frame_id);
  ```
- Plugin properties modified after `PLAYING` state must be protected by `GMutex`:
  ```cpp
  g_mutex_lock(&self->priv->lock);
  self->priv->threshold = g_value_get_float(value);
  g_mutex_unlock(&self->priv->lock);
  ```
- Always implement `start()` and `stop()` in `GstBaseTransform` subclasses for resource lifecycle — don't allocate GPU memory in `transform_ip`.
- Compile with `-Wall -Wextra -Werror` and fix all warnings before submitting.

## nvmsgconv customization

- When modifying `nvmsgconv.cpp`, always handle `NULL` `extMsg` gracefully. Not all detected objects will have custom event metadata attached.
- For the `msg2p-newapi=true` mode (reading from NvDsFrameMeta/NvDsObjectMeta directly), validate your schema against the actual metadata populated by the nvinfer output parser.
- Custom `nvds_msg2p` libraries must implement the **complete** interface: `nvds_msg2p_ctx_create`, `nvds_msg2p_ctx_destroy`, `nvds_msg2p`, and `nvds_msg2p_release`. Partial implementations crash at pipeline teardown.

## CUDA / GPU

- Always specify `gpu-id=0` (or the target GPU index) explicitly in configs — don't rely on defaults in multi-GPU systems.
- Use CUDA streams for async operations; don't synchronize the stream mid-pipeline unless benchmarking shows it's required.
- For Jetson / embedded targets: replace `nvcr.io/nvidia/deepstream` with `nvcr.io/nvidia/deepstream-l4t` and verify the ARM64 package compatibility.

## Docker and deployment

- Pin the DeepStream image tag explicitly (e.g., `nvidia/deepstream:9.0-triton-multiarch`). Never use `latest`.
- Always run containers with `--gpus all --runtime nvidia` (or `--runtime nvidia` for older Docker versions).
- Mount `/tmp/argus_socket` for USB camera / CSI sources.
- For headless server deployments, always include a `--no-display` flag or code path that removes `nvmultistreamtiler`, `nvdsosd`, and `nveglglessink` from the pipeline, replacing with `fakesink` or a file sink.

## TAO Toolkit integration

- Never hardcode the `ENCRYPTION_KEY` in spec files or scripts. Always read it from an environment variable or secret manager.
- After pruning, always retrain the model before export — a pruned-only model will have degraded accuracy.
- Document the exact TRT + CUDA + GPU driver version used to build each TensorRT engine file.
- Validate label maps between TAO spec `target_class_mapping` and DeepStream `labelfile-path` before running the full pipeline.
