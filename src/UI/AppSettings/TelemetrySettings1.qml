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
    property string _notConnectedStr:           qsTr("Not Connected")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var    _apmStartMavlinkStreams:    _mavlinkSettings.apmStartMavlinkStreams

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Ground Station")

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("MAVLink System ID")
            fact:               _mavlinkSettings.gcsMavlinkSystemID
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Send Heartbeat")
            fact:               _mavlinkSettings.sendGCSHeartbeat
        }
    }

    SettingsGroupLayout {
        id:                 mavlink2SigningGroup
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink 2 Signing")
        headingDescription: qsTr("The signing key should only be sent to the vehicle over a secure link.")
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
                label:                      qsTr("Key")
                fact:                       mavlink2SigningGroup._mavlink2SigningKey
            }

            QGCButton {
                text:       qsTr("Send to Vehicle")
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
            text:               qsTr("Signing key has changed. Remember to send it to the vehicle for it to take effect.")
            visible:            false
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink Forwarding")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable")
            fact:               _mavlinkSettings.forwardMavlink
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 20
            label:                      qsTr("Host Name / Address")
            fact:                       _mavlinkSettings.forwardMavlinkHostName
            visible:                    fact.visible
            enabled:                    _mavlinkSettings.forwardMavlink.rawValue
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Logging")
        visible:            !_disableAllDataPersistence

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save log after each flight")
            fact:               _telemetrySave
            visible:            fact.visible
            property Fact _telemetrySave: _mavlinkSettings.telemetrySave
        }

        // “armed”是飞行语义，这里改成“未启用/未开始任务也保存”
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save logs even when vehicle is not armed")
            fact:               _telemetrySaveNotArmed
            visible:            fact.visible
            enabled:            _mavlinkSettings.telemetrySave.rawValue
            property Fact _telemetrySaveNotArmed: _mavlinkSettings.telemetrySaveNotArmed
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save CSV telemetry log")
            fact:               _saveCsvTelemetry
            visible:            fact.visible
            property Fact _saveCsvTelemetry: _mavlinkSettings.saveCsvTelemetry
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Stream Rates (ArduPilot only)")
        visible:            _showAPMStreamRates

        QGCCheckBoxSlider {
            id:                 controllerByVehicleCheckBox
            Layout.fillWidth:   true
            text:               qsTr("Controlled by vehicle")
            checked:            !_apmStartMavlinkStreams.rawValue
            onClicked:          _apmStartMavlinkStreams.rawValue = !checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Raw Sensors")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extended Status")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("RC Channels")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Position")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 1")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 2")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 3")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Link Status (Current Vehicle)")

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total Messages Sent (estimated)")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkSentCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total Messages Received")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkReceivedCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total Messages Lost")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Loss Rate:")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossPercent.toFixed(0) + '%' : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Signing:")
            labelText:          _activeVehicle ? (_activeVehicle.mavlinkSigning ? qsTr("On") : qsTr("Off")) : _notConnectedStr
        }
    }
}
