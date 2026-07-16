# QGroundControl 本地化最终状态文档

> **目的**：指导将硬编码中文/硬编码英文（未包裹 qsTr）改为接入 QGC 正规本地化系统（英文 qsTr 源串 + `.ts` 翻译文件）。
> **产出**：此文档完成后，由子 Agent 串行按本文档修改 QML 源码；随后由主 Agent 串行填写 `translations/qgc_source_zh_CN.ts` 与 `translations/qgc_json_zh_CN.ts`。

---

## 1. QGC 本地化系统架构（必读）

### 1.1 翻译加载机制

`src/QGCApplication.cc` `setLanguage()`（L151-198）：

1. 从 `AppSettings::_qLocaleLanguageEarlyAccess()` 读取 locale（对应 `GeneralSettings1.qml` 中 `lockLang: "zh_CN"` 设置的 Fact `qLocaleLanguage`）
2. 若 `locale.name() != "en_US"`，加载三个 `QTranslator`：
   - `qgc_source_zh_CN` ← `translations/qgc_source_zh_CN.ts`（QML/C++ 源码 `qsTr()`/`tr()` 字符串）
   - `qgc_json_zh_CN` ← `translations/qgc_json_zh_CN.ts`（`FactMetaData.json` 中的 `shortDescription`/`longDescription`/`description`/`name`）
   - `qt_zh_CN`（Qt 库自带翻译）
3. 调用 `_qmlAppEngine->retranslate()` 刷新 UI

### 1.2 源字符串规则（铁律）

- **源代码中的 `qsTr("...")` 必须是英文**。`lupdate` 扫描源码生成 `qgc.ts`，Crowdin 以此为翻译源。
- **翻译写在 `.ts` 文件中**，不写源码。运行时 `qsTr("English")` 返回 `.ts` 中对应 `<translation>`；若无翻译则返回英文原串。
- `.ts` 条目匹配规则：`<source>` 必须与 `qsTr()` 参数**逐字符相同**；同名 context（默认为 QML 文件名去掉 `.qml`）下同 source 视为同一条目。
- `.ts` 中 `type="unfinished"` 的条目运行时**回退到英文 source**——必须补全翻译才会显示中文。

### 1.3 现状（已实测）

| 文件 | 总条目 | 已完成 | 未完成 |
|------|--------|--------|--------|
| `translations/qgc_source_zh_CN.ts` | 3382 | 1866 | 1516 |
| `translations/qgc_json_zh_CN.ts` | 799 | 250 | 549 |

`lupdate.yml` 是 `workflow_dispatch`（手动触发），此 fork 不会自动覆盖 `.ts`——编辑 `.ts` 安全。

---

## 2. 硬约束（禁止修改）

1. **绝不修改** `src/UI/AppSettings/SettingsPagesModel.qml`——它是设置页路由表，`qsTr("General")` 等保持英文，靠 `.ts` 翻译。
2. **绝不修改任何页面路由关系**：`SettingsPagesModel.qml` 的 `url:` 字段、`pageVisible:` 函数、`name:` 字段一律不动。
3. **绝不修改 Fact 系统引用**：所有 `fact:`、`_settingsManager.xxx.yyy`、`Fact { _xxx }` 引用保持原样，只改显示文本。
4. **绝不修改信号/属性名**：`property Fact _xxx`、`signal yyy` 等标识符不动。
5. **绝不删除** `*1.qml` 文件或其 `*1` 后缀——它们被 `SettingsPagesModel.qml` 引用，是激活文件。
6. **不修改不被 `SettingsPagesModel.qml` 引用的文件**（如 `LinkSettings1.qml`、`GeneralSettings.qml` 等原版）——它们是无用备份，留着即可。

---

## 3. 修改原则

### 3.1 三类修改

| 类型 | 当前状态 | 目标状态 | 操作 |
|------|----------|----------|------|
| A | `qsTr("中文")` | `qsTr("English")` | 替换参数为英文，英文来自原版对照或自定 |
| B | 裸字符串 `"中文"`（无 qsTr） | `qsTr("English")` | 补 `qsTr()` 包裹并改为英文 |
| C | 裸字符串 `"English"`（无 qsTr，但应翻译） | `qsTr("English")` | 补 `qsTr()` 包裹，内容不变 |

### 3.2 英文源串选取规则

1. **有原版对照**（如 `GeneralSettings1.qml` ↔ `GeneralSettings.qml`）：使用原版中对应位置的英文字符串。这样 `.ts` 已有条目可复用。
2. **定制功能**（原版无对应，如 "地面站连接"、"水质"）：自定一个合理英文短语。要求：全小写或标题式、简洁、语义明确、不含中文。
3. **含 `%1`/`%2` 占位符**：保留占位符，其余翻译。

### 3.3 字符串用于比较时的处理（关键）

某些文件用字符串作为 ComboBox model 并在 `onActivated` 中用 `===` 比较（如 `WaterQualityOverlay.qml`、`VideoSettings1.qml`）。

**规则**：model 设置和条件比较**两处**都要用**同一个** `qsTr("English")`。运行时 `qsTr()` 返回值由 locale 决定，两处一致即可正确比较。不要用裸字符串比较。

```qml
// 错误（当前）
model: ["点击刷新..."]
if (selected === "点击刷新...") { ... }

// 正确（目标）
model: [qsTr("Click to refresh...")]
if (selected === qsTr("Click to refresh...")) { ... }
```

### 3.4 保持 `%1` 等格式占位符

`qsTr("连接状态：%1").arg(x)` → `qsTr("Connection status: %1").arg(x)`，占位符位置可调但数量必须一致。

---

## 4. 逐文件修改清单

> **每个文件修改两步**：(1) 改 QML 源码（按表格）；(2) 改 `.ts` 文件（按 §7 规则）。
> **`.ts` 操作指引**：每个子节末尾标注 `[.ts 新增 context]` 或 `[.ts 增量 context]` 或 `[.ts 已有 context]`，指明该文件在 `translations/qgc_source_zh_CN.ts` 中的处理方式。

### 4.1 `src/UI/AppSettings/GeneralSettings1.qml`（35处，类型A）

**对照**：`GeneralSettings.qml` 原版。

| 行号 | 当前（中文） | 改为（英文） | 备注 |
|------|------------|------------|------|
| 105 | `qsTr("通用")` | `qsTr("General")` | |
| 109 | `qsTr("语言：中文 ")` | `qsTr("Language: Chinese ")` | 定制锁定文本 |
| 113 | `qsTr("配色方案")` | `qsTr("Color Scheme")` | |
| 120 | `qsTr("发送地面站位置")` | `qsTr("Stream GCS Position")` | |
| 128 | `qsTr("静音（关闭所有音频输出）")` | `qsTr("Mute all audio output")` | |
| 136 | `qsTr("Android：不保存到 SD 卡")` | `qsTr("Android: Don't save to SD card")` | 定制 |
| 143 | `qsTr("下次启动时清除所有设置")` | `qsTr("Clear all settings on next start")` | |
| 161 | `qsTr("界面缩放")` | `qsTr("UI Scaling")` | |
| 206 | `qsTr("应用加载/保存路径")` | `qsTr("Application Load/Save Path")` | |
| 210 | `qsTr("<默认位置>")` | `qsTr("<default location>")` | |
| 216 | `qsTr("浏览…")` | `qsTr("Browse")` | |
| 221 | `qsTr("选择文件保存/加载位置")` | `qsTr("Choose the location to save/load files")` | |
| 235 | `qsTr("单位")` | `qsTr("Units")` | |
| 238 | `qsTr("水平距离：米（m）")` | `qsTr("Horizontal Distance: m")` | 定制锁定文本 |
| 239 | `qsTr("垂直距离：米（m）")` | `qsTr("Vertical Distance: m")` | 定制 |
| 240 | `qsTr("面积：平方米（m²） ")` | `qsTr("Area: m²")` | 定制 |
| 241 | `qsTr("温度：摄氏度（°C）")` | `qsTr("Temperature: °C")` | 定制 |
| 250 | `qsTr("速度单位")` | `qsTr("Speed Unit")` | 定制 |
| 256 | `model: [ "m/s", "km/h" ]` | 不变（单位原始值，非显示） | **不改** |
| 274 | `qsTr("说明：距离/面积/温度为固定公制单位；速度仅支持 m/s 与 km/h。")` | `qsTr("Note: Distance/area/temperature are fixed to metric units; speed supports only m/s and km/h.")` | 定制 |
| 283 | `qsTr("品牌图片")` | `qsTr("Brand Image")` | |
| 295 | `qsTr("室内图片")` | `qsTr("Indoor Image")` | |
| 306 | `qsTr("浏览…")` | `qsTr("Browse")` | |
| 311 | `qsTr("选择自定义品牌图片文件")` | `qsTr("Choose custom brand image file")` | |
| 328 | `qsTr("室外图片")` | `qsTr("Outdoor Image")` | |
| 339 | `qsTr("浏览…")` | `qsTr("Browse")` | |
| 344 | `qsTr("选择自定义品牌图片文件")` | `qsTr("Choose custom brand image file")` | |
| 353 | `qsTr("重置图片")` | `qsTr("Reset Images")` | |
| 354 | `qsTr("重置")` | `qsTr("Reset")` | |

**不改**：L33-40 的 `lockLang`/`lockDist` 等原始值字符串（`"zh_CN"`、`"m"`、`"m²"` 等）——它们是 Fact rawValue，不是显示文本。

**`.ts` 操作**：[新增 context] 新增 `<context><name>GeneralSettings1</name>...</context>` 块，每个表格行的"改为"列作为 `<source>`，行号字段用 QML 中实际 `qsTr(...)` 所在行号。共约 30 个 `<message>`。

---

### 4.2 `src/UI/AppSettings/FlyViewSettings1.qml`（45处，类型A）

**对照**：`FlyViewSettings.qml` 原版。

| 行号 | 当前 | 改为 | 备注 |
|------|------|------|------|
| 36 | `qsTr("<无>")` | `qsTr("<None>")` | |
| 45 | `qsTr("通用")` | `qsTr("General")` | |
| 50 | `qsTr("启用出航前检查清单")` | `qsTr("Use Preflight Checklist")` | |
| 58 | `qsTr("强制执行检查清单")` | `qsTr("Enforce Preflight Checklist")` | |
| 67 | `qsTr("启用多载具面板（多船/多设备）")` | `qsTr("Enable Multi-Vehicle Panel")` | |
| 74 | `qsTr("地图始终跟随目标")` | `qsTr("Keep Map Centered On Vehicle")` | |
| 82 | `qsTr("显示遥测回放状态栏")` | `qsTr("Show Telemetry Log Replay Status Bar")` | |
| 90 | `qsTr("显示简易相机控制（DIGICAM_CONTROL）")` | `qsTr("Show simple camera controls (DIGICAM_CONTROL)")` | |
| 99 | `qsTr("根据设备位置更新返航点")` | `qsTr("Update return to home position based on device location.")` | |
| 107 | `qsTr("工具栏显示摇杆状态")` | `qsTr("Show Joystick Status in Toolbar")` | |
| 124 | `qsTr("MAVLink 动作")` | `qsTr("MAVLink Actions")` | |
| 125 | `qsTr("动作 JSON 文件需要放在"%1"目录下。").arg(...)` | `qsTr("Action JSON files should be created in the '%1' folder.").arg(...)` | |
| 129 | `qsTr("航行界面动作")` | `qsTr("Fly View Actions")` | |
| 142 | `qsTr("摇杆动作")` | `qsTr("Joystick Actions")` | |
| 159 | `qsTr("虚拟摇杆")` | `qsTr("Virtual Joystick")` | |
| 164 | `qsTr("启用")` | `qsTr("Enabled")` | |
| 172 | `qsTr("推进杆自动回中")` | `qsTr("Auto-Center Throttle")` | 船用语义 |
| 180 | `qsTr("左手模式（交换摇杆）")` | `qsTr("Left-Handed Mode (swap sticks)")` | |
| 192 | `qsTr("仪表")` | `qsTr("Instrument Panel")` | |
| 197 | `qsTr("指南针显示更多航向指示")` | `qsTr("Show additional heading indicators on Compass")` | |
| 204 | `qsTr("锁定指南针为船头向上")` | `qsTr("Lock Compass Nose-Up")` | |
| 215 | `qsTr("3D 视图")` | `qsTr("3D View")` | |
| 220 | `qsTr("启用")` | `qsTr("Enabled")` | |
| 237 | `qsTr("3D 地图文件：")` | `qsTr("3D Map File:")` | |
| 256 | `qsTr("清除")` | `qsTr("Clear")` | |
| 258 | `qsTr("请选择 OSM 文件")` | `qsTr("Please select an OSM file")` | |
| 264 | `qsTr("选择文件")` | `qsTr("Select File")` | |
| 277 | `qsTr("OpenStreetMap 文件 (*.osm)")` | `qsTr("OpenStreetMap files (*.osm)")` | |
| 278 | `qsTr("选择地图文件")` | `qsTr("Select map file")` | |
| 291 | `qsTr("平均建筑层高")` | `qsTr("Average Building Level Height")` | |
| 301 | `qsTr("显示偏置")` | `qsTr("Vehicles Altitude Bias")` | 参照原版 |

**`.ts` 操作**：[新增 context] 新增 `<context><name>FlyViewSettings1</name>...</context>` 块，约 31 个 `<message>`。

---

### 4.3 `src/UI/AppSettings/PlanViewSettings1.qml`（11处，类型A）

**对照**：`PlanViewSettings.qml` 原版。

| 行号 | 当前 | 改为 |
|------|------|------|
| 15 | `qsTr("任务规划（船用）")` | `qsTr("Plan View")` |
| 20 | `qsTr("默认任务高度")` | `qsTr("Default Mission Altitude")` |
| 28 | `qsTr("VTOL 转换距离")` | `qsTr("VTOL TransitionDistance")` |
| 36 | `qsTr("航线/图案生成时使用 MAV_CMD_CONDITION_GATE")` | `qsTr("Use MAV_CMD_CONDITION_GATE for pattern generation")` |
| 44 | `qsTr("任务不需要起飞条目")` | `qsTr("Missions do not require takeoff item")` |
| 52 | `qsTr("允许配置多个降落序列")` | `qsTr("Allow configuring multiple landing sequences")` |

**`.ts` 操作**：[新增 context] 新增 `<context><name>PlanViewSettings1</name>...</context>` 块，约 6 个 `<message>`。

---

### 4.4 `src/UI/AppSettings/VideoSettings1.qml`（28处，类型A）

**对照**：`VideoSettings.qml` 原版。

| 行号 | 当前 | 改为 | 备注 |
|------|------|------|------|
| 32 | `qsTr("视频源")` | `qsTr("Video Source")` | |
| 33 | `qsTr("MAVLink 相机视频流已自动配置")` | `qsTr("Mavlink camera stream is automatically configured")` | |
| 38 | `qsTr("来源")` | `qsTr("Source")` | |
| 47 | `qsTr("连接参数")` | `qsTr("Connection")` | |
| 54 | `qsTr("RTSP 地址")` | `qsTr("RTSP URL")` | |
| 64 | `qsTr("无人船")` | `qsTr("USV")` | 定制 |
| 72 | `qsTr("点击刷新...")` | `qsTr("Click to refresh...")` | 用于 model 和比较（见3.3） |
| 76 | `qsTr("点击刷新...")` | `qsTr("Click to refresh...")` | |
| 77 | `qsTr("无在线无人船")`、`qsTr("连接失败")`、`qsTr("请先配置地面站连接")`、`qsTr("解析失败")` | `qsTr("No USVs online")`、`qsTr("Connection failed")`、`qsTr("Please configure ground station connection first")`、`qsTr("Parse failed")` | |
| 85 | `qsTr("刷新")` | `qsTr("Refresh")` | |
| 92 | `qsTr("TCP 地址")` | `qsTr("TCP URL")` | |
| 101 | `qsTr("UDP 地址")` | `qsTr("UDP URL")` | |
| 109 | `qsTr("视频设置")` | `qsTr("Settings")` | |
| 114 | `qsTr("宽高比")` | `qsTr("Aspect Ratio")` | |
| 123 | `qsTr("未启用控制时停止录制")` | `qsTr("Stop recording when disarmed")` | |
| 130 | `qsTr("低延迟模式")` | `qsTr("Low Latency Mode")` | |
| 137 | `qsTr("强制视频解码器")` | 保持动态（原版用 `fact.shortDescription`）→ 改为 `qsTr("Force Video Decoder")` | 定制 |
| 146 | `qsTr("本地视频存储")` | `qsTr("Local Video Storage")` | |
| 150 | `qsTr("录制文件格式")` | `qsTr("Record File Format")` | |
| 157 | `qsTr("自动删除已保存录像")` | `qsTr("Auto-Delete Saved Recordings")` | |
| 164 | `qsTr("最大占用空间")` | `qsTr("Max Storage Usage")` | |
| 173 | `qsTr("请先配置地面站连接")` | `qsTr("Please configure ground station connection first")` | |
| 190 | `qsTr("无在线无人船")` | `qsTr("No USVs online")` | |
| 200 | `qsTr("解析失败")` | `qsTr("Parse failed")` | |
| 204 | `qsTr("连接失败")` | `qsTr("Connection failed")` | |

**`.ts` 操作**：[新增 context] 新增 `<context><name>VideoSettings1</name>...</context>` 块，约 26 个 `<message>`。注意 L72/L76、L173/L190、L200/L204 重复 source 只写一个 `<message>`。

---

### 4.5 `src/UI/AppSettings/LinkSettings.qml`（7处，类型A，激活文件）

**注意**：此文件大部分已是英文 qsTr，只有 L103-122 的"地面站连接" section 是硬编码中文（定制功能，原版无对应）。

| 行号 | 当前 | 改为 |
|------|------|------|
| 103 | `qsTr("地面站连接")` | `qsTr("Ground Station Connection")` |
| 106 | `qsTr("地面站名称")` | `qsTr("Ground Station Name")` |
| 111 | `qsTr("服务器地址")` | `qsTr("Server Address")` |
| 116 | `qsTr("服务器端口")` | `qsTr("Server Port")` |
| 121 | `qsTr("变更后手动创建连接")` | `qsTr("Manually create connection after change")` |
| 122 | `qsTr("确认")` | `qsTr("Confirm")` |

**不改**：L15 `qsTr("AutoConnect")`、L30 `qsTr("Pixhawk")` 等、L42 `qsTr("NMEA GPS")` 等已是英文 qsTr。

**`.ts` 操作**：[已有 context] 在既有 `<context><name>LinkSettings</name>...</context>` 块内、`</context>` 之前，增量追加 6 个 `<message>`（对应 §4.5 表格 6 行）。既有条目不动。

---

### 4.6 `src/UI/AppSettings/MapSettingsSimplified.qml`（39处，类型A）

**对照**：`MapSettings.qml` 原版。

| 行号 | 当前 | 改为 |
|------|------|------|
| 85 | `qsTr("地图服务器")` | `qsTr("Custom Map URL")` |
| 88 | `qsTr("IP 地址")` | `qsTr("Server URL")` |
| 94 | `qsTr("端口")` | 定制保留→`qsTr("Port")` |
| 107 | `qsTr("高程数据提供商")` | `qsTr("Elevation Provider")` |
| 123 | `qsTr("离线地图")` | `qsTr("Offline Maps")` |
| 124 | `qsTr("下载地图块数据供离线时使用")` | `qsTr("Download map tiles for use when offline")` |
| 137 | `qsTr("添加新地图块组")` | `qsTr("Add New Set")` |
| 138 | `qsTr("添加")` | `qsTr("Add")` |
| 144 | `qsTr("导入地图块")` | `qsTr("Import Map Tiles")` |
| 145 | `qsTr("导入")` | `qsTr("Import")` |
| 155 | `qsTr("导出地图块组")` | `qsTr("Export Map Tiles")` |
| 156 | `qsTr("导出")` | `qsTr("Export")` |
| 168 | `qsTr("正在导出")` / `qsTr("正在导入")` | `qsTr("Exporting")` / `qsTr("Importing")` |
| 187 | `qsTr("地图块缓存")` | `qsTr("Tile Cache")` |
| 202 | `qsTr("Tile Sets (*.%1)").arg(defaultSuffix)` | 不变（已是英文） |
| 220 | `qsTr("导出所选地图块组")` | `qsTr("Export Selected Tile Sets")` |
| 225 | `qsTr("导出地图块")` | `qsTr("Export Tiles")` |
| 249 | `qsTr("导入地图块组")` | `qsTr("Import TileSets")` |
| 254 | `qsTr("导入地图块")` | `qsTr("Import Tiles")` |
| 262 | `qsTr("追加到既存地图块组")` | `qsTr("Append to existing sets")` |
| 267 | `qsTr("替换既存地图块组")` | `qsTr("Replace existing sets")` |
| 279 | `qsTr("错误信息")` | `qsTr("Error Message")` |

**不改**：L85-97 的 `_customURLIPFact`、`_customURLPortFact` Fact 引用；L65 `_mapProviderFact.rawValue = "CustomURL"`（Fact rawValue，非显示）。

**`.ts` 操作**：[新增 context] 新增 `<context><name>MapSettingsSimplified</name>...</context>` 块，约 22 个 `<message>`。

---

### 4.7 `src/UI/AppSettings/NTRIPSettings1.qml`（21处，类型A）

**对照**：`NTRIPSettings.qml` 原版（但此定制文件结构不同，多为自定英文）。

**`_statusTextCN()` 函数（L15-30）**：函数名可保留或改为 `_statusText()`，其中所有 `qsTr("中文")` 改为：

| 行号 | 当前 | 改为 |
|------|------|------|
| 17 | `qsTr("NTRIP 管理器不可用")` | `qsTr("NTRIP Manager not available")` |
| 19 | `qsTr("未连接")` | `qsTr("Disconnected")` |
| 22 | `qsTr("已连接")` | `qsTr("Connected")` |
| 23 | `qsTr("连接中…")` | `qsTr("Connecting...")` |
| 24 | `qsTr("未连接")` | `qsTr("Disconnected")` |
| 25 | `qsTr("连接失败：%1").arg(s)` | `qsTr("Connection failed: %1").arg(s)` |
| 28 | `qsTr("未连接")` | `qsTr("Disconnected")` |

**UI 主体**：

| 行号 | 当前 | 改为 |
|------|------|------|
| 47 | `qsTr("RTK 差分（NTRIP）")` | `qsTr("RTK / NTRIP")` |
| 52 | `qsTr("启用 NTRIP/RTK 差分连接")` | `qsTr("Enable NTRIP/RTK")` |
| 71 | `qsTr("连接状态：%1").arg(...)` | `qsTr("Connection status: %1").arg(...)` |
| 77 | `qsTr("服务器地址")` | `qsTr("Server Address")` |
| 85 | `qsTr("端口")` | `qsTr("Port")` |
| 93 | `qsTr("用户名")` | `qsTr("Username")` |
| 101 | `qsTr("密码")` | `qsTr("Password")` |
| 110 | `qsTr("挂载点（Mountpoint）")` | `qsTr("Mountpoint")` |
| 119 | `qsTr("白名单（IP/设备）")` | `qsTr("Whitelist (IP/Device)")` |
| 128 | `qsTr("使用 SPARTN（暂不支持）")` | `qsTr("Use SPARTN (not supported yet)")` |

**`.ts` 操作**：[新增 context] 新增 `<context><name>NTRIPSettings1</name>...</context>` 块，约 18 个 `<message>`。注意 L19/24/28 重复 "Disconnected" 只写一个 `<message>`。

---

### 4.8 `src/UI/AppSettings/PX4LogTransferSettings1.qml`（42处，类型A）

**对照**：`PX4LogTransferSettings.qml` 原版。

| 行号 | 当前 | 改为 |
|------|------|------|
| 67 | `qsTr("日志记录")` | `qsTr("Log Record")` |
| 68 | `qsTr("上传日志前请先填写邮箱地址。")` | `qsTr("Please fill in the email address before uploading the log.")` |
| 95 | `qsTr("MAVLink 2.0 日志记录（仅 PX4）")` | `qsTr("MAVLink 2.0 Log Record (PX4 only)")` |
| 121 | `qsTr("手动开始/停止：")` | `qsTr("Manual Start/Stop:")` |
| 126 | `qsTr("开始记录")` | `qsTr("Start Record")` |
| 134 | `qsTr("停止记录")` | `qsTr("Stop Record")` |
| 145 | `qsTr("启用自动记录（设备启用时）")` | `qsTr("Enable auto record (when vehicle is armed)")` |
| 163 | `qsTr("MAVLink 2.0 日志上传（仅 PX4）")` | `qsTr("MAVLink 2.0 Log Upload (PX4 only)")` |
| 186 | `qsTr("上传邮箱：")` | `qsTr("Upload Email:")` |
| 204 | `qsTr("默认描述：")` | `qsTr("Default Description:")` |
| 221 | `qsTr("默认上传地址：")` | `qsTr("Default Upload URL:")` |
| 239 | `qsTr("视频地址：")` | `qsTr("Video URL:")` |
| 256 | `qsTr("风力：")` | `qsTr("Wind:")` |
| 265 | `qsTr("请选择")` | `qsTr("Please select")` |
| 266 | `qsTr("无风")` | `qsTr("No wind")` |
| 267 | `qsTr("微风")` | `qsTr("Breeze")` |
| 268 | `qsTr("大风")` | `qsTr("Strong wind")` |
| 269 | `qsTr("暴风")` | `qsTr("Storm")` |
| 291 | `qsTr("任务评价：")` | `qsTr("Flight Rating:")` |
| 300 | `qsTr("请选择")` | `qsTr("Please select")` |
| 301 | `qsTr("严重故障（操作原因）")` | `qsTr("Crash (pilot error)")` |
| 302 | `qsTr("严重故障（软件/硬件原因）")` | `qsTr("Crash (software/hardware failure)")` |
| 303 | `qsTr("不满意")` | `qsTr("Unsatisfactory")` |
| 304 | `qsTr("良好")` | `qsTr("Good")` |
| 305 | `qsTr("优秀")` | `qsTr("Great")` |
| 326 | `qsTr("补充说明：")` | `qsTr("Feedback:")` |
| 341 | `qsTr("允许公开该日志")` | `qsTr("Make this log public")` |
| 349 | `qsTr("启用自动上传日志")` | `qsTr("Enable auto upload")` |
| 360 | `qsTr("上传后删除日志文件")` | `qsTr("Delete log file after upload")` |
| 378 | `qsTr("已保存的日志文件")` | `qsTr("Saved Log Files")` |
| 449 | `qsTr("已上传")` | `qsTr("Uploaded")` |
| 475 | `qsTr("全选")` | `qsTr("Select All")` |
| 485 | `qsTr("全不选")` | `qsTr("Select None")` |
| 495 | `qsTr("删除所选")` | `qsTr("Delete Selected")` |
| 503 | `qsTr("删除日志文件")` | `qsTr("Delete Log Files")` |
| 504 | `qsTr("确认删除所选日志文件？")` | `qsTr("Are you sure you want to delete the selected log files?")` |
| 512 | `qsTr("上传所选")` | `qsTr("Upload Selected")` |
| 527 | `qsTr("上传日志文件")` | `qsTr("Upload Log Files")` |
| 528 | `qsTr("确认上传所选日志文件？")` | `qsTr("Are you sure you want to upload the selected log files?")` |
| 536 | `qsTr("取消上传")` | `qsTr("Cancel Upload")` |
| 545 | `qsTr("取消上传")` | `qsTr("Cancel Upload")` |
| 546 | `qsTr("确认取消上传过程？")` | `qsTr("Are you sure you want to cancel the upload?")` |

**不改**：`value: "crash_pilot"`、`value: "unsatisfactory"` 等 ListElement value 字段（程序标识符）。

**`.ts` 操作**：[新增 context] 新增 `<context><name>PX4LogTransferSettings1</name>...</context>` 块，约 41 个 `<message>`。注意 L265/300 重复 "Please select" 只写一个；L503/L545 重复 "Cancel Upload" 只写一个；L67/L503 等注意区分。

---

### 4.9 `src/UI/AppSettings/TelemetrySettings1.qml`（33处，类型A）

**对照**：`TelemetrySettings.qml` 原版。

| 行号 | 当前 | 改为 |
|------|------|------|
| 16 | `qsTr("未连接")` | `qsTr("Not Connected")` |
| 23 | `qsTr("地面站")` | `qsTr("Ground Station")` |
| 27 | `qsTr("MAVLink 系统 ID")` | `qsTr("MAVLink System ID")` |
| 33 | `qsTr("发送心跳包（Heartbeat）")` | `qsTr("Send Heartbeat")` |
| 41 | `qsTr("MAVLink 2 签名")` | `qsTr("MAVLink 2 Signing")` |
| 42 | `qsTr("签名密钥应仅通过安全链路发送到载具。")` | `qsTr("The signing key should only be sent to the vehicle over a secure link.")` |
| 58 | `qsTr("密钥")` | `qsTr("Key")` |
| 63 | `qsTr("发送到载具")` | `qsTr("Send to Vehicle")` |
| 75 | `qsTr("签名密钥已变更。如需生效，请记得发送到载具。")` | `qsTr("Signing key has changed. Remember to send it to the vehicle for it to take effect.")` |
| 82 | `qsTr("MAVLink 转发")` | `qsTr("MAVLink Forwarding")` |
| 86 | `qsTr("启用")` | `qsTr("Enable")` |
| 94 | `qsTr("主机名 / 地址")` | `qsTr("Host Name / Address")` |
| 103 | `qsTr("日志")` | `qsTr("Logging")` |
| 108 | `qsTr("每次任务结束后保存日志")` | `qsTr("Save log after each flight")` |
| 117 | `qsTr("即使载具未启用/未进入任务状态也保存日志")` | `qsTr("Save logs even when vehicle is not armed")` |
| 126 | `qsTr("保存遥测数据 CSV 日志")` | `qsTr("Save CSV telemetry log")` |
| 135 | `qsTr("数据流频率（仅 ArduPilot）")` | `qsTr("Stream Rates (ArduPilot only)")` |
| 141 | `qsTr("由载具端控制")` | `qsTr("Controlled by vehicle")` |
| 148 | `qsTr("原始传感器")` | `qsTr("Raw Sensors")` |
| 156 | `qsTr("扩展状态")` | `qsTr("Extended Status")` |
| 164 | `qsTr("RC 通道")` | `qsTr("RC Channels")` |
| 172 | `qsTr("位置")` | `qsTr("Position")` |
| 180 | `qsTr("附加 1")` | `qsTr("Extra 1")` |
| 188 | `qsTr("附加 2")` | `qsTr("Extra 2")` |
| 196 | `qsTr("附加 3")` | `qsTr("Extra 3")` |
| 205 | `qsTr("链路状态（当前载具）")` | `qsTr("Link Status (Current Vehicle)")` |
| 209 | `qsTr("已发送消息总数（估算）")` | `qsTr("Total Messages Sent (estimated)")` |
| 215 | `qsTr("已接收消息总数")` | `qsTr("Total Messages Received")` |
| 221 | `qsTr("丢包总数")` | `qsTr("Total Messages Lost")` |
| 227 | `qsTr("丢包率：")` | `qsTr("Loss Rate:")` |
| 233 | `qsTr("签名：")` | `qsTr("Signing:")` |
| 234 | `qsTr("开启")` / `qsTr("关闭")` | `qsTr("On")` / `qsTr("Off")` |

**`.ts` 操作**：[新增 context] 新增 `<context><name>TelemetrySettings1</name>...</context>` 块，约 32 个 `<message>`。

---

### 4.10 `src/UI/AppSettings/HelpSettings1.qml`（4处，类型A）

| 行号 | 当前 | 改为 |
|------|------|------|
| 26 | `qsTr("QGroundControl 用户指南")` | `qsTr("QGroundControl User Guide")` |
| 33 | `qsTr("PX4 用户讨论区")` | `qsTr("PX4 Users Forum")` |
| 40 | `qsTr("ArduPilot 用户讨论区")` | `qsTr("ArduPilot Users Forum")` |
| 47 | `qsTr("QGroundControl Discord 频道")` | `qsTr("QGroundControl Discord Channel")` |

**`.ts` 操作**：[新增 context] 新增 `<context><name>HelpSettings1</name>...</context>` 块，4 个 `<message>`。

---

### 4.11 `src/UI/AppSettings/MockLink1.qml`（10处，类型A）

| 行号 | 当前 | 改为 |
|------|------|------|
| 31 | `qsTr("发送状态信息 + 语音播报")` | `qsTr("Send status text + voice broadcast")` |
| 35 | `qsTr("启动模拟：PX4 载具")` | `qsTr("Start Mock: PX4 Vehicle")` |
| 41 | `qsTr("启动模拟：ArduPilot 多旋翼（ArduCopter）")` | `qsTr("Start Mock: ArduPilot Multirotor (ArduCopter)")` |
| 48 | `qsTr("启动模拟：ArduPilot 固定翼（ArduPlane）")` | `qsTr("Start Mock: ArduPilot Fixed Wing (ArduPlane)")` |
| 56 | `qsTr("启动模拟：水下/船用（ArduSub）")` | `qsTr("Start Mock: Sub/Boat (ArduSub)")` |
| 64 | `qsTr("启动模拟：地面/通用平台（ArduRover）")` | `qsTr("Start Mock: Ground/General (ArduRover)")` |
| 71 | `qsTr("启动模拟：通用载具")` | `qsTr("Start Mock: Generic Vehicle")` |
| 77 | `qsTr("停止一个模拟连接")` | `qsTr("Stop one mock link")` |

**`.ts` 操作**：[新增 context] 新增 `<context><name>MockLink1</name>...</context>` 块，8 个 `<message>`。

---

### 4.12 `src/UI/AppSettings/DebugWindow1.qml`（30处，类型A）

此文件是调试页面（`ScreenTools.isDebug` 才可见），但为完整性仍需改。

| 行号 | 当前 | 改为 |
|------|------|------|
| 25 | `qsTr("Qt 平台：")` | `qsTr("Qt Platform: ")` |
| 27 | `qsTr("字号 10")` | `qsTr("Size 10")` |
| 29 | `qsTr("默认字体宽度：")` | `qsTr("Default Font Width: ")` |
| 31 | `qsTr("字号 10.5")` | `qsTr("Size 10.5")` |
| 33 | `qsTr("默认字体高度：")` | `qsTr("Default Font Height: ")` |
| 35 | `qsTr("字号 11")` | `qsTr("Size 11")` |
| 37 | `qsTr("默认字体像素大小：")` | `qsTr("Default Font Pixel Size: ")` |
| 39 | `qsTr("字号 11.5")` | `qsTr("Size 11.5")` |
| 41 | `qsTr("默认字体点大小：")` | `qsTr("Default Font Point Size: ")` |
| 43 | `qsTr("字号 12")` | `qsTr("Size 12")` |
| 45 | `qsTr("QML 桌面可用区域：")` | `qsTr("QML Desktop Available Area: ")` |
| 47 | `qsTr("字号 12.5")` | `qsTr("Size 12.5")` |
| 49 | `qsTr("QML 屏幕尺寸：")` | `qsTr("QML Screen Size: ")` |
| 51 | `qsTr("字号 13")` | `qsTr("Size 13")` |
| 53 | `qsTr("QML 像素密度：")` | `qsTr("QML Pixel Density: ")` |
| 55 | `qsTr("字号 13.5")` | `qsTr("Size 13.5")` |
| 57 | `qsTr("QML 像素比例：")` | `qsTr("QML Pixel Ratio: ")` |
| 59 | `qsTr("字号 14")` | `qsTr("Size 14")` |
| 61 | `qsTr("默认点大小：")` | `qsTr("Default Point Size: ")` |
| 63 | `qsTr("字号 14.5")` | `qsTr("Size 14.5")` |
| 65 | `qsTr("计算得到的字体高度：")` | `qsTr("Calculated Font Height: ")` |
| 67 | `qsTr("字号 15")` | `qsTr("Size 15")` |
| 69 | `qsTr("计算得到的屏幕高度：")` | `qsTr("Calculated Screen Height: ")` |
| 71 | `qsTr("字号 15.5")` | `qsTr("Size 15.5")` |
| 73 | `qsTr("计算得到的屏幕宽度：")` | `qsTr("Calculated Screen Width: ")` |
| 75 | `qsTr("字号 16")` | `qsTr("Size 16")` |
| 77 | `qsTr("桌面可用宽度：")` | `qsTr("Desktop Available Width: ")` |
| 79 | `qsTr("字号 16.5")` | `qsTr("Size 16.5")` |
| 81 | `qsTr("桌面可用高度：")` | `qsTr("Desktop Available Height: ")` |
| 83 | `qsTr("字号 17")` | `qsTr("Size 17")` |

**`.ts` 操作**：[新增 context] 新增 `<context><name>DebugWindow1</name>...</context>` 块，30 个 `<message>`。

---

### 4.13 `src/UI/toolbar/SelectViewDropdown.qml`（1处，类型A）

| 行号 | 当前 | 改为 | 备注 |
|------|------|------|------|
| 62 | `qsTr("水质")` | `qsTr("Water Quality")` | 定制按钮 |

**不改**：L22 `qsTr("Fly")`、L35 `qsTr("Plan")`、L48 `qsTr("Analyze")`、L76 `qsTr("Configure")`、L90 `qsTr("Settings")`、L105 `qsTr("Close")`、L124 `qsTr("%1 Version").arg(...)`——已是英文 qsTr，靠 `.ts` 翻译。

**`.ts` 操作**：[已有 context] 在既有 `<context><name>SelectViewDropdown</name>...</context>` 块内增量追加 1 个 `<message>`（`<source>Water Quality</source>`）。

---

### 4.14 `src/FlyView/WaterQualityOverlay.qml`（8处，混合类型A+B）

**关键**：此文件有硬编码中文未包裹 qsTr（类型B），也有已包裹的（类型A）。还有用于比较的硬编码中文字符串。按 3.3 节规则处理。

| 行号 | 当前 | 改为 | 类型 |
|------|------|------|------|
| 49 | `qsTr("选择无人船")` | `qsTr("Select USV")` | A |
| 57 | `model: ["点击刷新..."]` | `model: [qsTr("Click to refresh...")]` | B |
| 61 | `if(val !== "Click Refresh..." && val !== "No Boats")` | `if(val !== qsTr("Click to refresh...") && val !== qsTr("No Boats"))` | B |
| 72 | `text: "刷新"` | `text: qsTr("Refresh")` | B |
| 79 | `text: qsTr("无人船名称:")` | `text: qsTr("USV Name:")` | A |
| 83 | `model: ["Click Refresh..."]` | `model: [qsTr("Click to refresh...")]` | B（已是英文但缺 qsTr） |
| 86 | `if(val !== "Click Refresh..." && val !== "No Boats")` | `if(val !== qsTr("Click to refresh...") && val !== qsTr("No Boats"))` | B |
| 97 | `qsTr("等待数据...")` / `qsTr("未连接")` | `qsTr("Waiting for data...")` / `qsTr("Disconnected")` | A |
| 168 | `comboModel.push("无在线无人船")` | `comboModel.push(qsTr("No Boats"))` | B |
| 187 | `boatSelector.model = ["连接失败"]` | `boatSelector.model = [qsTr("Connection failed")]` | B |
| 196 | `if (boatName === "无在线无人船" \|\| boatName === "点击刷新..." \|\| boatName === "连接失败")` | `if (boatName === qsTr("No Boats") \|\| boatName === qsTr("Click to refresh...") \|\| boatName === qsTr("Connection failed"))` | B |
| 315 | `boatSelector.model = boats.length ? boats : ["No Boats"]` | `boatSelector.model = boats.length ? boats : [qsTr("No Boats")]` | B |
| 322 | `console.log("Auto-connecting to first boat:", boats[0])` | 不变（debug log） | **不改** |

**不改**：L170 `titleText: "Time (s)"`、L179 `titleText: "Value"`（ChartView 轴标题，可后续考虑但当前不改）；L14-16 `serverIp`/`httpPort`/`wsPort`（配置值）；L307-331 `refreshBoatList()` 中的 HTTP 逻辑和 `json.boats`（API 数据）。

**注意**：L83 `model: ["Click Refresh..."]` 当前是**英文但无 qsTr**——按类型B补 `qsTr()`。L61/L86 的比较 `!== "Click Refresh..."` 也需对应改。

**`.ts` 操作**：[新增 context] 新增 `<context><name>WaterQualityOverlay</name>...</context>` 块，约 8 个 `<message>`。注意重复 source（"Click to refresh..."、"No Boats"、"Connection failed"、"Disconnected"）每个 context 内只写一个 `<message>`，但有多处 `<location>` 行号时合并到一条 `<message>` 内多个 `<location>` 子元素，或简单起见只写一条 `<location>`。

---

### 4.15 `src/FlyView/FlyViewCustomLayer.qml`（4处，类型B）

**关键**：4 处硬编码中文前缀未包裹 qsTr。

| 行号 | 当前 | 改为 |
|------|------|------|
| 63 | `text: "PH值: " + ...` | `text: qsTr("PH: ") + ...` |
| 67 | `text: "水温: " + ...` | `text: qsTr("Water Temp: ") + ...` |
| 71 | `text: "浊度: " + ...` | `text: qsTr("Turbidity: ") + ...` |
| 75 | `text: "电导率: " + ...` | `text: qsTr("Conductivity: ") + ...` |

**`.ts` 操作**：[新增 context] 新增 `<context><name>FlyViewCustomLayer</name>...</context>` 块，4 个 `<message>`（"PH: "、"Water Temp: "、"Turbidity: "、"Conductivity: "）。

---

### 4.16 `src/FlyView/VTOLChecklist.qml`（1处，类型C）

| 行号 | 当前 | 改为 |
|------|------|------|
| 70 | `name: "Wind & weather"` | `name: qsTr("Wind & weather")` |

**不改**：L14 `qsTr("VTOL Initial Checks")` 等已是英文 qsTr。

**`.ts` 操作**：[已有 context] 在既有 `<context><name>VTOLChecklist</name>...</context>` 块内增量追加 1 个 `<message>`（`<source>Wind & weather</source>`，注意 XML 中 `&` 必须转义为 `&amp;`）。

---

### 4.17 `src/FlyView/FlyViewWidgetLayer.qml`（不改）

**不改**。此文件含 `var targetFamily = "等线"`（字体名，非显示文本）和中文注释。字体名不翻译，注释不影响显示。

---

## 5. 不需修改的文件清单（已正确接入本地化）

以下文件已用英文 `qsTr()` 包裹，靠 `.ts` 翻译即可，**无需改源码**：

### AnalyzeView（全部，英文 qsTr）
- `AnalyzeView.qml`、`LogDownloadPage.qml`、`MAVLinkConsolePage.qml`、`MAVLinkInspectorPage.qml`、`GeoTagPage.qml`、`VibrationPage.qml`

### FlyView（大部分，英文 qsTr）
- 所有 Checklist 文件（`DefaultChecklist.qml`、`FixedWingChecklist.qml`、`MultiRotorChecklist.qml`、`RoverChecklist.qml`、`SubChecklist.qml`、`VTOLChecklist.qml` 除 L70）
- 所有 PreFlight 检查文件
- `FlyViewMap.qml`、`FlyViewMissionCompleteDialog.qml`、`FlyViewPreFlightChecklistPopup.qml`、`FlyViewToolStripActionList.qml`、`FlyViewTopRightPanel.qml`、`FlyViewVideo.qml`、`FlyViewGripperButton.qml`、`FlyViewGripperDropPanel.qml`、`FlyViewAdditionalActionsButton.qml`
- `GuidedActionsController.qml`（大量英文 qsTr）
- `MultiVehicleList.qml`、`VehicleWarnings.qml`、`TerrainProgress.qml`、`ProximityRadarValues.qml`、`FlightDisplayViewVideo.qml`

### toolbar（大部分，英文 qsTr）
- `ArmedIndicator.qml`、`EscIndicator.qml`、`EscIndicatorPage.qml`、`JoystickIndicator.qml`、`TelemetryRSSIIndicator.qml`、`RCRSSIIndicator.qml`、`MultiVehicleSelector.qml`、`ModeIndicator.qml`、`VehicleGPSIndicator.qml`、`RTKGPSIndicator.qml`、`GimbalIndicator.qml`、`GCSControlIndicator.qml`、`RemoteIDIndicator.qml`

### AppSettings（不被引用的原版，不改）
- `GeneralSettings.qml`、`FlyViewSettings.qml`、`PlanViewSettings.qml`、`VideoSettings.qml`、`LinkSettings1.qml`、`MapSettings.qml`、`NTRIPSettings.qml`、`PX4LogTransferSettings.qml`、`TelemetrySettings.qml`、`HelpSettings.qml`、`MockLink.qml`、`DebugWindow.qml`
- `ADSBServerSettings.qml`、`BluetoothSettings.qml`、`LogReplaySettings.qml`、`MockLinkSettings.qml`、`RemoteIDSettings.qml`、`SerialSettings.qml`、`SettingsPage.qml`、`TcpSettings.qml`、`UdpSettings.qml`、`QmlTest.qml`

---

## 6. 验证步骤（子 Agent 完成后执行）

1. `lsp_diagnostics` 检查所有修改过的 QML 文件无语法错误。
2. 用 `grep` 确认 4 个目录中 `qsTr("` 后不再接中文字符（`[\x{4e00}-\x{9fff}]`）。
3. 用 `grep` 确认 4 个目录中裸字符串 `"中文"`（无 qsTr 包裹）已消除（注释除外）。
4. 构建项目（若条件允许），运行 QGC，确认：
   - 设置页菜单显示中文（靠 `.ts`）
   - 各设置页内容显示中文（靠 `.ts`）
   - toolbar 各指示器弹出页显示中文（靠 `.ts`）
   - FlyView 水质覆盖层显示中文（靠 `.ts`）
   - 若 `.ts` 未填翻译，应显示英文（不报错、不乱码）

---

## 7. `.ts` 文件修改（子 Agent 必读）

### 7.0 红线（子 Agent 绝对禁止项）

> **严禁子 Agent 直接写中文翻译。**
>
> 子 Agent **不具备**主 Agent 已收集的术语对译上下文（航模/无人船领域术语、PX4/ArduPilot/MAVLink 中文文档约定、QGC 既有翻译惯例）。子 Agent 若尝试自我收敛翻译，会导向**灾难性后果**或**永不停止的 overthinking**。
>
> **子 Agent 的职责仅限**：
> 1. 按 §4 修改 QML 源码（英文源串已在 §4 表格中给出，直接使用，不要自行拟定）。
> 2. 按 §7.1 向 `.ts` 文件**添加空条目**（`type="unfinished"` 且 `<translation>` 为空）。
> 3. 按 §7.2 处理既有 context 的增量。
> 4. **不填任何 `<translation>` 的内容**——保持空或保留既有英文回退。
>
> 翻译内容**由主 Agent 在子 Agent 全部完成后**，串行地用网络搜索逐词确认后填写。

### 7.1 向 `translations/qgc_source_zh_CN.ts` 添加空条目（新 context）

**何时需要**：子 Agent 修改的 QML 文件，若其文件名（去掉 `.qml`）在 `.ts` 中尚不存在 `<context>` 块，则需要新增。

**当前实测：以下 context 在 `qgc_source_zh_CN.ts` 中尚不存在**（lupdate 未扫过这些定制文件）：
- `GeneralSettings1`
- `FlyViewSettings1`
- `PlanViewSettings1`
- `VideoSettings1`
- `LinkSettings`（已存在，但当前条目缺上述新增英文源串——按 §7.2 处理）
- `MapSettingsSimplified`
- `NTRIPSettings1`
- `PX4LogTransferSettings1`
- `TelemetrySettings1`
- `HelpSettings1`
- `MockLink1`
- `DebugWindow1`
- `SelectViewDropdown`（已存在，但缺 "Water Quality" 条目——按 §7.2 处理）
- `WaterQualityOverlay`
- `FlyViewCustomLayer`

**当前已存在 context**（子 Agent 增量处理）：
- `VTOLChecklist`（缺 "Wind & weather" 条目——按 §7.2）
- `LinkSettings`（缺 §4.5 新增英文源串条目——按 §7.2）
- `SelectViewDropdown`（缺 "Water Quality" 条目——按 §7.2）

**添加格式**：在 `.ts` 文件最后一个 `</context>` 之后、`</TS>` 之前，追加新 `<context>` 块。每个块结构：

```xml
  <context>
    <name>文件名去掉.qml</name>
    <message>
      <location filename="../src/路径/文件名.qml" line="行号"/>
      <source>英文源串（与 qsTr 参数逐字符一致）</source>
      <translation type="unfinished"></translation>
    </message>
    <!-- 同一文件的其他 qsTr 字符串，每个一个 <message> -->
  </context>
```

**示例**（假设子 Agent 改完 `GeneralSettings1.qml` 后）：

```xml
  <context>
    <name>GeneralSettings1</name>
    <message>
      <location filename="../src/UI/AppSettings/GeneralSettings1.qml" line="105"/>
      <source>General</source>
      <translation type="unfinished"></translation>
    </message>
    <message>
      <location filename="../src/UI/AppSettings/GeneralSettings1.qml" line="109"/>
      <source>Language: Chinese </source>
      <translation type="unfinished"></translation>
    </message>
    <!-- ... §4.1 表格中每一行都对应一个 <message> ... -->
  </context>
```

**关键规则**：
- `<source>` 必须与 QML 中 `qsTr("...")` 的参数**逐字符相同**（含空格、标点、占位符 `%1`）。否则运行时匹配失败，回退显示英文。
- `<translation type="unfinished"></translation>` 保持空——**子 Agent 不写翻译**。
- `<location>` 的 `filename` 用相对路径 `../src/...`（与既有条目风格一致），`line` 填 QML 中 `qsTr(...)` 所在行号（子 Agent 改完后实际行号）。
- 同一 source 在同一 context 内只出现一次。若同一文件多次用同一英文串（如 `qsTr("Enabled")` 出现两次），只写一个 `<message>`，但 `<location>` 可有多条（lupdate 会合并；手动添加时写一条即可）。
- **XML 转义**：`<source>` 中若含 `&`、`<`、`>`、`'`、`"`，必须转义为 `&amp;`、`&lt;`、`&gt;`、`&apos;`、`&quot;`。例如 `qsTr("Wind & weather")` → `<source>Wind &amp; weather</source>`；`qsTr("<None>")` → `<source>&lt;None&gt;</source>`；`qsTr("Language: Chinese ")` 中冒号无空格但若含特殊字符也需转义。

### 7.2 向既有 context 增量添加空条目

**何时需要**：文件已在 `.ts` 中有 `<context>` 块，但子 Agent 新增了英文源串（原文件无对应 `<message>`）。

**操作**：在该 `<context>` 块内、其 `</context>` 之前，追加 `<message>` 块（格式同 §7.1）。

**示例**：`SelectViewDropdown` 已有 context，缺 "Water Quality"。子 Agent 改完 `SelectViewDropdown.qml` L62 后追加：

```xml
    <message>
      <location filename="../src/UI/toolbar/SelectViewDropdown.qml" line="62"/>
      <source>Water Quality</source>
      <translation type="unfinished"></translation>
    </message>
```

追加位置：`<context><name>SelectViewDropdown</name>...</context>` 块内、`</context>` 之前。

### 7.3 处理已废弃的中文 source 条目

**场景**：`.ts` 中可能存在旧条目，其 `<source>` 是中文（因为之前 `lupdate` 扫到了硬编码中文 qsTr）。子 Agent 把源码改为英文 qsTr 后，这些旧中文 source 条目失效。

**操作**：**不要删除旧条目**。留着无害（`type="obsolete"` 或 lupdate 下次跑会自动标记 obsolete）。子 Agent 只需确保新增的英文 source 条目存在即可。

### 7.4 `qgc_json_zh_CN.ts`

**不修改**。此文件由 `qgc-lupdate-json.py` 从 `*.FactMetaData.json` 生成。子 Agent 不碰 JSON 元数据文件，因此此 `.ts` 无需手动改。主 Agent 后续若发现 `fact.shortDescription` 绑定的显示文本未翻译，再处理。

### 7.5 子 Agent 完成后交付物

子 Agent 完成后，应确保：
1. §4 中列出的 17 个 QML 文件均已修改，`qsTr()` 参数全部为英文（或裸字符串已补 `qsTr()` 包裹）。
2. `translations/qgc_source_zh_CN.ts` 中新增了对应 context/message 空条目（`type="unfinished"` 且 translation 为空）。
3. `lsp_diagnostics` 在每个修改过的 QML 文件上无错误。
4. 报告新增的英文 source 串清单（便于主 Agent 后续翻译）。

**子 Agent 绝对不要**：
- 填写任何 `<translation>` 的内容
- 修改 `qgc_json_zh_CN.ts`
- 修改任何 `*.FactMetaData.json`
- 删除既有 `.ts` 条目
- 修改 §2 列出的禁改文件
- 运行 `lupdate` 或 `qgc-lupdate.sh`（可能覆盖既有翻译，且需要 Qt 工具链）

---

## 8. 执行顺序（严格串行）

### 阶段 1：子 Agent（串行，禁止并行）

子 Agent 按 §4 顺序逐文件修改 QML 源码，每改完一个文件：
1. 立即 `lsp_diagnostics` 验证该文件无语法错误。
2. 立即按 §7.1 或 §7.2 在 `translations/qgc_source_zh_CN.ts` 中添加对应空条目（`type="unfinished"`、translation 为空）。
3. 记录该文件新增的英文 source 串清单（便于主 Agent 后续翻译）。

**子 Agent 必须串行工作**，原因：
- 多次修改可能产生重叠的英文 source 串（如 `qsTr("Enabled")` 出现在多个文件），需要在 `.ts` 中精确控制每个 context 的条目。
- 子 Agent 可能在过程中发现 §4 表格遗漏的字符串，需要即时补全文档第 4 节对应条目（不重写表格，只追加遗漏行）。

**子 Agent 严禁**：
- 直接写任何中文翻译（§7.0 红线）
- 并行修改多个文件
- 修改 §2 列出的禁改文件
- 运行 `lupdate` 或 `qgc-lupdate.sh`

### 阶段 2：主 Agent（串行，子 Agent 全部完成后）

主 Agent 在子 Agent 完成后，串行地：
1. 用网络搜索逐词确认每个英文 source 串的中文翻译（参照航模/无人船术语对译表，结合上下文）。
2. 直接编辑 `translations/qgc_source_zh_CN.ts`，在 `<translation type="unfinished"></translation>` 中填入中文。
3. 检查 `qgc_json_zh_CN.ts` 中与显示文本相关的 `shortDescription`/`longDescription` 条目，必要时补全（仅在确认为显示文本时）。
4. 构建验证。

### 阶段 3：验证

1. `lsp_diagnostics` 检查所有修改过的 QML 文件无语法错误。
2. 用 `grep` 确认 4 个目录中 `qsTr("` 后不再接中文字符（`[\x{4e00}-\x{9fff}]`）。
3. 用 `grep` 确认 4 个目录中裸字符串 `"中文"`（无 qsTr 包裹）已消除（注释除外）。
4. 构建项目（若条件允许），运行 QGC，确认：
   - 设置页菜单显示中文（靠 `.ts`）
   - 各设置页内容显示中文（靠 `.ts`）
   - toolbar 各指示器弹出页显示中文（靠 `.ts`）
   - FlyView 水质覆盖层显示中文（靠 `.ts`）
   - 若 `.ts` 未填翻译，应显示英文（不报错、不乱码）
