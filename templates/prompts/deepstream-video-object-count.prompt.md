---
name: deepstream-video-object-count
description: 'Generate a DeepStream pyservicemaker Python app that reads a video file, runs ResNet18 inference, displays bounding boxes, and counts the number of detected objects per class.'
agent: agent
tools:
  - read
  - edit
  - create
  - search
---

Use DeepStream SDK pyservicemaker APIs to develop the Python application that can do the following.

- Read from file, decode the video and infer using ResNet18 TrafficCamNet model.
- Display the bounding box around detected objects using OSD.
- Count the number of objects detected.

**Important**
Use `nvurisrcbin` as source to automatically handle various types of video files.

Save the generated code in `video_object_count_app` directory.
Also generate a `README.md` with setup instructions and how to run the application.
