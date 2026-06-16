import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    property var    _settingsManager:                       QGroundControl.settingsManager
    property var    _flyViewSettings:                       _settingsManager.flyViewSettings
    property var    _mavlinkActionsSettings:                _settingsManager.mavlinkActionsSettings

    // 手动操控/虚拟摇杆
    property Fact   _virtualJoystick:                       _settingsManager.appSettings.virtualJoystick
    property Fact   _virtualJoystickAutoCenterThrottle:     _settingsManager.appSettings.virtualJoystickAutoCenterThrottle
    property Fact   _virtualJoystickLeftHandedMode:         _settingsManager.appSettings.virtualJoystickLeftHandedMode

    // 多载具面板（多船/多设备）
    property Fact   _enableMultiVehiclePanel:               _settingsManager.appSettings.enableMultiVehiclePanel

    // 航向/仪表
    property Fact   _showAdditionalIndicatorsCompass:       _flyViewSettings.showAdditionalIndicatorsCompass
    property Fact   _lockNoseUpCompass:                     _flyViewSettings.lockNoseUpCompass

    // 3D
    property var    _viewer3DSettings:                      _settingsManager.viewer3DSettings
    property Fact   _viewer3DEnabled:                       _viewer3DSettings.enabled
    property Fact   _viewer3DOsmFilePath:                   _viewer3DSettings.osmFilePath
    property Fact   _viewer3DBuildingLevelHeight:           _viewer3DSettings.buildingLevelHeight
    property Fact   _viewer3DAltitudeBias:                  _viewer3DSettings.altitudeBias

    function mavlinkActionList() {
        var fileModel = QGCFileDialogController.getFiles(_settingsManager.appSettings.mavlinkActionsSavePath, "*.json")
        fileModel.unshift(qsTr("<无>"))
        return fileModel
    }

    // =========================================================
    // 通用（船用/航行界面）
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("通用")

        FactCheckBoxSlider {
            id:                 useCheckList
            Layout.fillWidth:   true
            text:               qsTr("启用出航前检查清单")
            fact:               _useChecklist
            visible:            _useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length
            property Fact _useChecklist: _settingsManager.appSettings.useChecklist
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("强制执行检查清单")
            fact:               _enforceChecklist
            enabled:            _settingsManager.appSettings.useChecklist.value
            visible:            useCheckList.visible && _enforceChecklist.visible
            property Fact _enforceChecklist: _settingsManager.appSettings.enforceChecklist
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("启用多载具面板（多船/多设备）")
            fact:               _enableMultiVehiclePanel
            visible:            _enableMultiVehiclePanel.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("地图始终跟随目标")
            fact:               _keepMapCenteredOnVehicle
            visible:            _keepMapCenteredOnVehicle.visible
            property Fact _keepMapCenteredOnVehicle: _flyViewSettings.keepMapCenteredOnVehicle
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("显示遥测回放状态栏")
            fact:               _showLogReplayStatusBar
            visible:            _showLogReplayStatusBar.visible
            property Fact _showLogReplayStatusBar: _flyViewSettings.showLogReplayStatusBar
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("显示简易相机控制（DIGICAM_CONTROL）")
            visible:            _showSimpleCameraControl.visible
            fact:               _showSimpleCameraControl
            property Fact _showSimpleCameraControl: _flyViewSettings.showSimpleCameraControl
        }

        // 原文是“根据设备位置更新返航点”，船用语义改成“更新返航/返航点”
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("根据设备位置更新返航点")
            fact:               _updateHomePosition
            visible:            _updateHomePosition.visible
            property Fact _updateHomePosition: _flyViewSettings.updateHomePosition
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("工具栏显示摇杆状态")
            fact:               _flyViewSettings.showJoystickIndicatorInToolbar
            visible:            fact.visible
        }
    }

    // =========================================================
    // 引导/高度/飞行命令：船用不需要 -> 整块删除
    // （原来的 Guided Commands SettingsGroupLayout 不要了）
    // =========================================================

    // =========================================================
    // MAVLink 动作（如果你们用按键/按钮触发动作，船也有意义）
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:       true
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 35
        heading:                qsTr("MAVLink 动作")
        headingDescription:     qsTr("动作 JSON 文件需要放在“%1”目录下。").arg(QGroundControl.settingsManager.appSettings.mavlinkActionsSavePath)

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("航行界面动作")
            model:              mavlinkActionList()
            onActivated:        (index) => index == 0 ? _mavlinkActionsSettings.flyViewActionsFile.rawValue = "" : _mavlinkActionsSettings.flyViewActionsFile.rawValue = comboBox.currentText
            enabled:            model.length > 1

            Component.onCompleted: {
                var index = comboBox.find(_mavlinkActionsSettings.flyViewActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
        }

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("摇杆动作")
            model:              mavlinkActionList()
            onActivated:        (index) => index == 0 ? _mavlinkActionsSettings.joystickActionsFile.rawValue = "" : _mavlinkActionsSettings.joystickActionsFile.rawValue = comboBox.currentText
            enabled:            model.length > 1

            Component.onCompleted: {
                var index = comboBox.find(_mavlinkActionsSettings.joystickActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
        }
    }

    // =========================================================
    // 虚拟摇杆（船用保留）
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("虚拟摇杆")
        visible:            _virtualJoystick.visible || _virtualJoystickAutoCenterThrottle.visible || _virtualJoystickLeftHandedMode.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("启用")
            visible:            _virtualJoystick.visible
            fact:               _virtualJoystick
        }

        // 这里“Throttle”对船更像“油门/推进”，改成推进杆自回中
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("推进杆自动回中")
            visible:            _virtualJoystickAutoCenterThrottle.visible
            enabled:            _virtualJoystick.rawValue
            fact:               _virtualJoystickAutoCenterThrottle
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("左手模式（交换摇杆）")
            visible:            _virtualJoystickLeftHandedMode.visible
            enabled:            _virtualJoystick.rawValue
            fact:               _virtualJoystickLeftHandedMode
        }
    }

    // =========================================================
    // 仪表（航向相关，船用保留）
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("仪表")
        visible:            _showAdditionalIndicatorsCompass.visible || _lockNoseUpCompass.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("指南针显示更多航向指示")
            visible:            _showAdditionalIndicatorsCompass.visible
            fact:               _showAdditionalIndicatorsCompass
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("锁定指南针为船头向上")
            visible:            _lockNoseUpCompass.visible
            fact:               _lockNoseUpCompass
        }
    }

    // =========================================================
    // 3D 视图（可选，船用也可保留；把“高度偏置”文案改成更通用）
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("3D 视图")
        visible:            _viewer3DSettings.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("启用")
            fact:               _viewer3DEnabled
            visible:            _viewer3DEnabled.visible
        }

        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DOsmFilePath.rawValue

            RowLayout {
                Layout.fillWidth:   true
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    wrapMode:   Text.WordWrap
                    text:       qsTr("3D 地图文件：")
                }

                QGCTextField {
                    id:                 osmFileTextField
                    height:             ScreenTools.defaultFontPixelWidth * 4.5
                    unitsLabel:         ""
                    showUnits:          false
                    Layout.fillWidth:   true
                    readOnly:           true
                    text:               _viewer3DOsmFilePath.rawValue
                }
            }

            RowLayout {
                Layout.alignment:   Qt.AlignRight
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCButton {
                    text: qsTr("清除")
                    onClicked: {
                        osmFileTextField.text = qsTr("请选择 OSM 文件")
                        _viewer3DOsmFilePath.value = osmFileTextField.text
                    }
                }

                QGCButton {
                    text: qsTr("选择文件")
                    onClicked: {
                        var filename = _viewer3DOsmFilePath.rawValue
                        const found = filename.match(/(.*)[\/\\]/)
                        if (found) {
                            filename = found[1] || ""
                            fileDialog.folder = (filename[0] === "/") ? (filename.slice(1)) : (filename)
                        }
                        fileDialog.openForLoad()
                    }

                    QGCFileDialog {
                        id:             fileDialog
                        nameFilters:    [qsTr("OpenStreetMap 文件 (*.osm)")]
                        title:          qsTr("选择地图文件")

                        onAcceptedForLoad: (file) => {
                            osmFileTextField.text = file
                            _viewer3DOsmFilePath.value = osmFileTextField.text
                        }
                    }
                }
            }
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("平均建筑层高")
            fact:               _viewer3DBuildingLevelHeight
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DBuildingLevelHeight.visible
        }

        // 原来是 Vehicles Altitude Bias（载具高度偏置），船用改成“显示高度/垂向偏置”
        // 如果你们完全不想出现“高度”字样，也可以改成“显示偏置”
        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("显示偏置")
            fact:               _viewer3DAltitudeBias
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DAltitudeBias.visible
        }
    }
}
