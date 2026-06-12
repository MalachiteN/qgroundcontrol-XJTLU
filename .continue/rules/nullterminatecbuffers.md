---
globs: '["**/*.cc","**/*.cpp","**/*.h"]'
description: Prevent garbage characters or buffer overruns when handling
  fixed-size char arrays that might not be null-terminated by source.
alwaysApply: false
---

When converting C-style character arrays (especially fixed-size buffers from MAVLink/structs) to C++ Strings/QString, always ensure the buffer is null-terminated or use explicit length limits/memcpy to a safe buffer before conversion.