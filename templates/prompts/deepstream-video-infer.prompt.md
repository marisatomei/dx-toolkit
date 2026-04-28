---
name: deepstream-video-infer
description: 'Generate a DeepStream pyservicemaker Python app that reads a video file, runs ResNet18 TrafficCamNet inference, and displays bounding boxes. Uses nvurisrcbin for universal source handling.'
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

**Important**
Use `nvurisrcbin` as source to automatically handle various types of video files.

Save the generated code in `video_infer_app` directory.
Also generate a `README.md` with setup instructions and how to run the application.
