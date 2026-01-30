---
globs: "**/*"
description: Comprehensive documentation of the distributed system architecture,
  including port mappings, communication protocols, and specific implementation
  details for Video Streaming, Mavlink Routing, and Map Services.
alwaysApply: true
---

Follow the defined architecture and implementation patterns for Server, IoT (Pi), and GroundStation (QGC) development.

# 无人船协同作业系统开发文档 (Cross-Device USV System)

本文档定义了云端服务器、边缘端（无人船/树莓派）及地面站（QGroundControl）三端协同的系统架构与开发规范。最新版本已整合 `f624b50` 和 `343bb0a` 的变更。

## 1. 基础设施与环境 (Infrastructure)

### 1.1 服务器信息
*   **Public IP**: `111.229.242.175` (Immutable)
*   **OS/Env**: Linux / Docker Hybrid
*   **Workspaces**:
    *   `【服务器】`: Docker Compose, Python FastAPIs, Routing Services
    *   `【树莓派】`: Ubuntu/Linux, Python, MAVLink, FFmpeg, Hardware IO
    *   `【地面站】`: Windows/Linux/Mac, Qt 5/6, QML, C++ (QGroundControl Fork)

### 1.2 端口规划表
| 端口 | 用途 | 协议 | 服务组件 | 备注 |
| :--- | :--- | :--- | :--- | :--- |
| **5000** | 专有地图瓦片服务 | HTTP | Tianditu Hybrid Map | 外部服务，提供 `/tianditu/hybrid/{z}/{x}/{y}` |
| **8554** | RTSP 拉流接口 | TCP/UDP | MediaMTX | 现：仅地面站从此拉取视频 将来：在地面站拉流的基础上，也允许树莓派向此端口推RTSP流 |
| **10000**| 视频流推流入口 | 现：UDP (MPEG-TS) | MediaMTX | 现：树莓派向此端口推MPEG-TS流 |
| **11451**| Mavlink容器编排API | HTTP | Router Manager | 管理动态路由容器 /connect |
| **11452**| 水质数据遥测服务 | WebSocket | *Pending Dev* | 实时数据转发 |
| **11453**| 水质数据遥测服务 | HTTP | *Pending Dev* | 列表查询 |
| **Var**  | 动态 Mavlink 端口 | TCP | mavlink-routerd | 由 11451 动态分配 (20000-30000) |

---

## 2. 现有模块与架构 (Existing Modules)

### 2.1 视频直播系统 (Video Streaming) - Phase 1 Basic
基于 `mediamtx` 实现低延迟图传转发。
*   **Server**: 监听 UDP:10000 接收 MPEG-TS，暴露 RTSP:8554 供拉取。
    *   配置文件: `mediamtx.yml`
*   **Edge (Pi)**: 使用 `ffmpeg` 推送流。
    *   Systemd Service: `ffmpeg` RTSP -> UDP MPEG-TS。
*   **Client (QGC)**:
    *   当前: 拉取固定地址 `rtsp://111.229.242.175:8554/live`。
    *   *Plan*: 需升级为动态多船支持（见 Phase 1 要求）。

### 2.2 Mavlink 控制路由 (Command & Control) - Phase 2 Basic
动态分配 MAVLink 路由器，处理 QGC <-> PX4 通信。
*   **Server**:
    *   `router_manager.py`: 响应 HTTP GET `/connect?name={StationName}`。
    *   **Response**: `{ "success": true, "data": { "port": 200xx } }`。
    *   资源管理: 容器在无心跳后自动销毁 (via `heartbeat_monitor.py`).
*   **Client (QGC)** (Impl in `f624b50`):
    *   **LinkManager**: 新增 `_addGroundStationTcpLink` 逻辑。
    *   **流程**: 启动时/配置变更时 -> GET `/connect` -> 解析 Port -> 创建 TCP Link -> Auto Connect。
    *   **UI**: `LinkSettings.qml` 新增 "地面站连接" 配置组 (Server Host, Port, Name)。

### 2.3 私有地图服务 (Map Service) - Phase 0 Complete
强制 QGC 使用私有天地图融合服务。
*   **Client (QGC)** (Impl in `343bb0a`):
    *   **UI**: `MapSettingsSimplified.qml` 替换原版设置页。
    *   **逻辑**: 强制锁定 Map Provider 为 `CustomURL`。
    *   **URL构建**: `http://{customURLIP}:{customURLPort}/tianditu/hybrid/{z}/{x}/{y}`。
    *   **配置**: 仅保留 IP/Port 输入框，移除了 Google/Bing 等选项。

---

## 3. 待开发功能与规范 (Features & Requirements)

### 3.1 [Phase 1] 视频流动态路由与管理 (Refinement)
*   **目标**: 支持多地面站、多船的定向图传。
*   **Server**:
    *   维护 `Dict[StationName, List[BoatName]]`。
    *   支持 RTSP 路径: `rtsp://...:8554/{StationName}/{BoatName}`。
    *   鉴权: 启用 RTSP Auth。
*   **Client (QGC)**:
    *   UI 需支持下拉选择 BoatName (基于 StationName 查询 Server)。
    *   动态构建 RTSP URL。

### 3.2 [Phase 2] 安全增强型 Mavlink 路由
*   **Server**: 为 `/connect` 添加 Authentication & Rate Limiting。

### 3.3 [Phase 3] 实时水质数据遥测 (Water Quality Router)
*   **Server**: 新增 Py 服务 (Port 11452、11453)。
    *   WebSocket: `ws://...:11452/uav/{StationName}/{BoatName}`（用于无人船上传数据）、`ws://...:11452/gcs/{StationName}/{BoatName}`（向地面站推送数据）。
    *   维护 `Dict[StationName, List[BoatName]]`。向所有连接到 `ws://...:11452/gcs/{StationName}/{BoatName}` 的 WebSocket 推送该船数据。
    *   HTTP Discovery: `GET ...:11453/list?name={StationName}`。
    *   **注意**：多台电脑可能以相同地面站名称连接，在逻辑上作为同一地面站工作。禁止假设地面站名字和IP地址/Socket是一一对应关系。
*   **Edge (Pi)**:
    *   WebSocket 客户端，0.1s 周期发送 JSON。
    *   Schema: `{ "timestamp": int, "data": [{ "name": "PH", "value": 7.2 }, ...] }`。
    *   非阻塞发送，超时丢弃。
*   **Client (QGC)**:
    *   先向 `GET ...:11453/list?name={StationName}` 发请求取得无人船列表，然后主动建立到 `ws://...:11452/gcs/{StationName}/{BoatName}` 的连接，之后被动接受服务器从该 WebSocket 推送而来的数据
    *   Map Overlay: 半透明实时数据显示，上面需要有下拉列表，用于选择船名。
    *   Analysis View: 时域信号图表。
    *   动态解析 JSON 数据结构，不硬编码传感器类型。

### 3.4 [Phase 4] 统一注册与认证 (Registry & Auth)
*   集中式身份管理，集成到 Video, Mavlink, Data Router。
*   必须包含审计日志 (Audit Logs)。

---

## 4. 文件系统索引 (File System Index)
*   `【服务器】`:
    *   `./router_manager.py`: Mavlink Orchestrator
    *   `./mediamtx.yml`: MediaMTX Config
*   `【地面站】`:
    *   `src/Comms/LinkManager.cc`: 自动连接逻辑核心
    *   `src/UI/AppSettings/LinkSettings.qml`: 连接配置 UI
    *   `src/UI/AppSettings/MapSettingsSimplified.qml`: 地图强制定制 UI