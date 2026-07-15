# 最终目标状态文档 — 四项 UI 修改

## 概述
对 QGroundControl（无人船地面控制站）进行四项独立修改。

---

## 任务 1：移除全部姿态显示，仅保留罗盘

### 背景
- 默认仪表 `IntegratedCompassAttitude.qml` 使用 `IntegratedAttitudeIndicator`（弧线式 roll/pitch）+ `QGCCompassWidget`
- 可选仪表 `HorizontalCompassAttitude.qml` / `VerticalCompassAttitude.qml` 使用 `QGCAttitudeWidget`（传统水平仪）+ `QGCCompassWidget`
- 船没有主动 roll/pitch，全部移除姿态，仅保留罗盘

### 文件改动

#### `src/FlightMap/Widgets/IntegratedCompassAttitude.qml`
- 移除两个 `IntegratedAttitudeIndicator` 实例
- 移除 `attitudeSize`、`attitudeSpacing`、`_totalAttitudeSize` 属性
- `extraInset` 改为 `0`
- `implicitWidth` / `implicitHeight` 改为 `compassRadius * 2`
- 罗盘 Rectangle 的 `y` 偏移移除（从 `_totalAttitudeSize` → `0`）
- 保留 `QGCCompassWidget` 及所有罗盘功能

#### `src/FlightMap/Widgets/HorizontalCompassAttitude.qml`
- 移除 `QGCAttitudeWidget`
- `_innerRadius` 公式从 `(width - _topBottomMargin * 3) / 4` → `(width - _topBottomMargin * 2) / 2`
- 罗盘居中放置
- 保留 `DeadMouseArea`、`QGCCompassWidget`

#### `src/FlightMap/Widgets/VerticalCompassAttitude.qml`
- 移除 `QGCAttitudeWidget`
- `height` 从 `_outerRadius * 4` → `_outerRadius * 2`
- 罗盘居中放置

#### `src/Settings/FlyView.SettingsGroup.json`
- `enumStrings`: `"Integrated Compass & Attitude,Horizontal Compass & Attitude,Large Vertical"` → `"Integrated Compass,Horizontal Compass,Large Compass"`
- `enumValues` 不变（文件路径不变）

---

## 任务 2：主菜单居中

### 背景
- 点击 QGC Logo → `showToolSelectDialog()` → `showIndicatorDrawer(toolSelectComponent, null)`
- `indicatorItem` 为 null 时，`calcXPosition()` 返回 `_margins`（左上角）
- 其他指示器（电池、GPS 等）传入具体控件引用，不受影响

### 文件改动

#### `src/UI/MainWindow.qml`
- `calcXPosition()` 的 `else` 分支（`indicatorItem` 为 null）改为返回水平居中坐标
- 新增 `calcYPosition()` 函数：`indicatorItem` 为 null 时返回垂直居中坐标，否则保持 `ScreenTools.toolbarHeight + _margins`
- Popup 的 `y` 属性从硬编码改为 `calcYPosition()` 绑定

---

## 任务 3：载具图标改为船俯视图

### 背景
- `VehicleMapItem.qml` 使用 `vehicle.vehicleImageOpaque` → 默认返回 `/qmlimages/vehicleArrowOpaque.svg`
- `vehicleArrowOutline.svg` 未在任何 QML 中使用（仅 C++ 定义），但替换以保持一致
- SVG 需要船头朝上（随航向旋转）
- 实际文件路径：`src/FlightMap/Images/vehicleArrowOpaque.svg` 和 `vehicleArrowOutline.svg`

### 文件改动

#### `src/FlightMap/Images/vehicleArrowOpaque.svg`
替换为船俯视图 SVG：
- 船体：深青色 (#004a5a) 填充，深色描边 (#001a2a)
- 舱室：亮青色 (#00a8a8) 圆角矩形
- 船头指示：浅色 (#e0e6ed) 三角形

#### `src/FlightMap/Images/vehicleArrowOutline.svg`
替换为轮廓版船图标（仅描边无填充）

---

## 任务 4：QGC 软件内 Logo 更换

### 背景
- `QGCLogoFull.svg`（resources/）：工具栏按钮 + 地图地面站位置（无航向时）
- `QGCLogoArrow.svg`（resources/）：地图地面站位置（有航向时，会旋转）
- `QGCLogoWhite.svg`（resources/）：设置菜单/页面图标（深色背景上使用）
- 三个文件都需替换为 Arctic Teal 主题风格的新设计

### 文件改动

#### `resources/QGCLogoFull.svg`
- 白色圆角方框 + 青色 (#00798c) 内框 + 白色船型轮廓 + 青色 (#00a8a8) 舱室点缀

#### `resources/QGCLogoArrow.svg`
- 白色圆角方框 + 青色 (#00798c) 内框 + 白色方向箭头

#### `resources/QGCLogoWhite.svg`
- 透明背景 + 白色描边圆角框 + 白色船型轮廓 + 青色 (#00a8a8) 舱室点缀
- viewBox 0 0 215 215（与原始一致）

---

## 不在范围内
- 不替换操作系统级应用图标（.ico / .icns / .png）
- 不修改 C++ 代码（FirmwarePlugin.h 的 vehicleImageOpaque 默认路径不变，SVG 内容替换即可）
- 不删除 QGCArtificialHorizon.qml / QGCAttitudeWidget.qml / IntegratedAttitudeIndicator.qml 文件本身（保留备用，仅从仪表组件中移除引用）

## 已知不确定项（不阻塞实施）
- 移除姿态后仪表面板的视觉间距是否需要微调（可在编译验证后调整）
- 船图标在卫星地图上的可见度（深青色在深色水域上可能偏低，编译后实测确认）
