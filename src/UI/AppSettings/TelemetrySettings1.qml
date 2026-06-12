import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _mavlinkSettings:           _settingsManager.mavlinkSettings
    property var    _appSettings:               _settingsManager.appSettings
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr:           qsTr("未连接")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var    _apmStartMavlinkStreams:    _mavlinkSettings.apmStartMavlinkStreams

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("地面站")

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("MAVLink 系统 ID")
            fact:               _mavlinkSettings.gcsMavlinkSystemID
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("发送心跳包（Heartbeat）")
            fact:               _mavlinkSettings.sendGCSHeartbeat
        }
    }

    SettingsGroupLayout {
        id:                 mavlink2SigningGroup
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink 2 签名")
        headingDescription: qsTr("签名密钥应仅通过安全链路发送到载具。")
        visible:            _mavlink2SigningKey.visible

        property Fact _mavlink2SigningKey: _mavlinkSettings.mavlink2SigningKey

        Connections {
            target: mavlink2SigningGroup._mavlink2SigningKey
            function onRawValueChanged(value) { sendToVehiclePrompt.visible = true }
        }

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            LabelledFactTextField {
                Layout.fillWidth:           true
                textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 32
                label:                      qsTr("密钥")
                fact:                       mavlink2SigningGroup._mavlink2SigningKey
            }

            QGCButton {
                text:       qsTr("发送到载具")
                enabled:    _activeVehicle
                onClicked: {
                    sendToVehiclePrompt.visible = false
                    _activeVehicle.sendSetupSigning()
                }
            }
        }

        QGCLabel {
            id:                 sendToVehiclePrompt
            Layout.fillWidth:   true
            text:               qsTr("签名密钥已变更。如需生效，请记得发送到载具。")
            visible:            false
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink 转发")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("启用")
            fact:               _mavlinkSettings.forwardMavlink
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 20
            label:                      qsTr("主机名 / 地址")
            fact:                       _mavlinkSettings.forwardMavlinkHostName
            visible:                    fact.visible
            enabled:                    _mavlinkSettings.forwardMavlink.rawValue
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("日志")
        visible:            !_disableAllDataPersistence

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("每次任务结束后保存日志")
            fact:               _telemetrySave
            visible:            fact.visible
            property Fact _telemetrySave: _mavlinkSettings.telemetrySave
        }

        // “armed”是飞行语义，这里改成“未启用/未开始任务也保存”
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("即使载具未启用/未进入任务状态也保存日志")
            fact:               _telemetrySaveNotArmed
            visible:            fact.visible
            enabled:            _mavlinkSettings.telemetrySave.rawValue
            property Fact _telemetrySaveNotArmed: _mavlinkSettings.telemetrySaveNotArmed
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("保存遥测数据 CSV 日志")
            fact:               _saveCsvTelemetry
            visible:            fact.visible
            property Fact _saveCsvTelemetry: _mavlinkSettings.saveCsvTelemetry
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("数据流频率（仅 ArduPilot）")
        visible:            _showAPMStreamRates

        QGCCheckBoxSlider {
            id:                 controllerByVehicleCheckBox
            Layout.fillWidth:   true
            text:               qsTr("由载具端控制")
            checked:            !_apmStartMavlinkStreams.rawValue
            onClicked:          _apmStartMavlinkStreams.rawValue = !checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("原始传感器")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("扩展状态")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("RC 通道")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("位置")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("附加 1")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("附加 2")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("附加 3")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("链路状态（当前载具）")

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("已发送消息总数（估算）")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkSentCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("已接收消息总数")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkReceivedCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("丢包总数")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("丢包率：")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossPercent.toFixed(0) + '%' : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("签名：")
            labelText:          _activeVehicle ? (_activeVehicle.mavlinkSigning ? qsTr("开启") : qsTr("关闭")) : _notConnectedStr
        }
    }
}
