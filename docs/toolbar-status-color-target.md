# Toolbar Status Color — Final Target State

## Goal

1. The vehicle connection status color (red/green/yellow/teal) must cover the **entire** toolbar width, not just the QGC logo + MainStatusIndicator area.
2. All text and SVG icons in the toolbar must automatically switch between **white** and **black** based on the luminance of the status background color, ensuring readability on both dark and light status colors.

## Resolved Decisions

### Status Colors and Luminance

| Status | `_mainStatusBGColor` | Luminance | Text Color |
|---|---|---|---|
| Comms Lost / Can't Arm | `"red"` (#FF0000) | 0.299 | White |
| Ready / Armed & Healthy | `"green"` (#008000) | 0.295 | White |
| Warnings | `"yellow"` (#FFFF00) | 0.886 | Black |
| Disconnected | `qgcPal.brandingPurple` (#00798c) | 0.342 | White |

**Luminance formula**: `0.299 * r + 0.587 * g + 0.114 * b`
**Threshold**: luminance > 0.5 → black text (`#000000`), otherwise white text (`#ffffff`)

### Background Opacity

The full-width status background uses the same opacity as the current gradientBackground: `qgcPal.windowTransparent.a` (≈0.8 in dark theme).

### Property Propagation Pattern

- `FlyViewToolBar.qml` computes `_toolbarTextColor` and binds it to child components
- Each toolbar indicator declares `property color toolbarTextColor: "#ffffff"` (default white)
- `FlyViewToolBarIndicators.qml` passes the property to dynamically loaded indicators via `onLoaded`
- Status-specific colors (battery icon, ESC OK/ERR, RemoteID outer icon, joystick yellow/red, GCS control green) are **NOT** changed — they convey status meaning

## Implementation Details

### 1. FlyViewToolBar.qml

- Add luminance computation function and `_toolbarTextColor` property
- Replace fragmented background rectangles with a single full-width Rectangle:
  ```qml
  Rectangle {
      anchors.fill: parent
      opacity: qgcPal.windowTransparent.a
      color: _mainStatusBGColor
  }
  ```
  Placed as first child (lowest z-order), behind the QGCFlickable
- Remove the old `gradientBackground` and the separate background rectangles in leftPanel/centerPanel/rightPanel
- Bind `toolbarTextColor` on: MainStatusIndicator, FlightModeIndicator, FlyViewToolBarIndicators
- Pass `toolbarTextColor` to GuidedActionConfirm (for close button XDelete icon)

### 2. MainStatusIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.windowTransparentText` → `toolbarTextColor` for:
  - `mainStatusLabel.color`
  - `vehicleMessagesIcon.getIconColor()` default return (NOT the orange/red overrides — those are status colors)
  - `vtolModeLabel.color`

### 3. FlightModeIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.windowTransparentText` → `toolbarTextColor` for:
  - `flightModeIcon.color`
  - `flightModeLabel.color`
  - `vtolModeLabel` — this one uses default QGCLabel color, change to `toolbarTextColor`

### 4. FlyViewToolBarIndicators.qml

- Add `property color toolbarTextColor: "#ffffff"`
- In both Repeaters' Loaders, add `onLoaded` to set `toolbarTextColor` on loaded item if it has the property:
  ```qml
  onLoaded: {
      if (item && item.toolbarTextColor !== undefined) {
          item.toolbarTextColor = Qt.binding(function() { return control.toolbarTextColor })
      }
  }
  ```

### 5. GPSIndicator.qml (base for VehicleGPSIndicator & RTKGPSIndicator)

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.windowTransparentText` → `toolbarTextColor` for: gpsLabel, gpsIcon, gps count label, hdop label

### 6. BatteryIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.windowTransparentText` → `toolbarTextColor` for: percentage and voltage text labels
- **DO NOT change** `getBatteryColor()` — battery icon status color stays

### 7. TelemetryRSSIIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.buttonText` → `toolbarTextColor` for: telemIcon

### 8. RCRSSIIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.buttonText` → `toolbarTextColor` for: rssiRow RC icon
- Pass `toolbarTextColor` to SignalStrength

### 9. SignalStrength.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.buttonText` → `toolbarTextColor` for: QGCColoredImage color

### 10. RemoteIDIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.text` → `toolbarTextColor` for: inner RidIconText icon
- **DO NOT change** outer icon `getRidColor()` — status color stays

### 11. GimbalIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.windowTransparentText` → `toolbarTextColor` for: gimbalIndicatorIcon, gimbalIdLabel, statusLabel, pitchLabel, panLabel

### 12. EscIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.windowTransparentText` → `toolbarTextColor` for: escIcon, online motor count label
- **DO NOT change** `getEscStatusColor()` — OK/ERR status color stays

### 13. JoystickIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change the "joystick ready" case from `qgcPal.windowTransparentText` → `toolbarTextColor`
- **DO NOT change** "yellow" and "red" status returns

### 14. MultiVehicleSelector.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.text` → `toolbarTextColor` for: airplane icon
- The QGCLabel text — check if it uses default color, if so bind to `toolbarTextColor`

### 15. GCSControlIndicator.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.text` → `toolbarTextColor` for: controlIndicatorIconLine, controlIndicatorIconGCS (when not in control)
- **DO NOT change** `qgcPal.colorGreen` — control status color stays

### 16. GuidedActionConfirm.qml

- Add `property color toolbarTextColor: "#ffffff"`
- Change `qgcPal.text` → `toolbarTextColor` for: closeButton (XDelete icon) color

## Out of Scope

- QGCToolBarButton logo: uses `color: "transparent"`, SVG keeps original colors — no change
- Disconnect button (QGCButton): has its own background and standard button styling — no change
- GuidedActionConfirm's QGCDelayButton and QGCCheckBox: have own backgrounds — no change
- ToolStripHoverButton: NOT in the top toolbar, uses own background — no change
- APMSupportForwardingIndicator: uses plain Image (not QGCColoredImage) — no change needed, but if property is set on it, it's harmless
- PX4/APM firmware-specific indicator expanded pages: use standard QGC controls — no change
- Plan view toolbar: separate toolbar, not affected
