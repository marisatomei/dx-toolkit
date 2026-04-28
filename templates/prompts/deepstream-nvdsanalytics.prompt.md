---
name: deepstream-nvdsanalytics
description: 'Generate a DeepStream pyservicemaker Python app using nvdsanalytics for ROI filtering, line-crossing, overcrowding detection, and direction analysis. Uses Flow APIs and FPS probe.'
agent: agent
tools:
  - read
  - edit
  - create
  - search
---

Use DeepStream SDK pyservicemaker APIs to develop the Python application that can do the following.

- Read from files, decode the videos and infer using ResNet18 model.
- Display the bounding box around detected objects using OSD.
- Use `nvdsanalytics` to perform ROI filtering, line-crossing, overcrowding, and direction-detection
  analysis.
- Print out all nvdsanalytics user meta information for both objects and frames.
- Display the nvdsanalytics information on video.
- Add the built-in probe `measure_fps_probe` after `nvinfer` to measure the pipeline's FPS.

**nvdsanalytics configuration:**

- Stream 0:
  - ROIs: regions `[295;643;579;634;642;913;56;828]`; Label: `TEST`; Classes: all
  - Line-crossing:
    - Line 0: start `(789, 672)` → end `(1084, 900)`
    - Line 1: start `(851, 773)` → end `(1203, 732)`

**Important**

Save the generated code and configuration files in `deepstream_nvdsanalytics_test_app` directory.
Use pyservicemaker **Flow APIs** instead of Pipeline APIs.
