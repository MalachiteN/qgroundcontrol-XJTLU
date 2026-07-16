import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.NTRIP 1.0

SettingsPage {
    property var  _settingsManager: QGroundControl.settingsManager
    property var  _ntrip:           _settingsManager.ntripSettings
    property Fact _enabled:         _ntrip.ntripServerConnectEnabled

    function _statusTextCN() {
        try {
            if (!NTRIPManager) return qsTr("NTRIP Manager not available")
            var s = (NTRIPManager.ntripStatus || "")
            if (s.length === 0) return qsTr("Disconnected")

            var sl = s.toLowerCase()
            if (sl.includes("connected"))   return qsTr("Connected")
            if (sl.includes("connecting"))  return qsTr("Connecting...")
            if (sl.includes("disconnected"))return qsTr("Disconnected")
            if (sl.includes("error") || sl.includes("failed")) return qsTr("Connection failed: %1").arg(s)
            return s   // 兜底：显示原始状态
        } catch (e) {
            return qsTr("Disconnected")
        }
    }

    function _statusColor() {
        try {
            if (!NTRIPManager) return qgcPal.text
            var s = (NTRIPManager.ntripStatus || "").toLowerCase()
            if (s.includes("connected")) return qgcPal.colorGreen
            if (s.includes("connecting")) return qgcPal.colorOrange
            if (s.includes("error") || s.includes("failed")) return qgcPal.colorRed
            return qgcPal.text
        } catch (e) {
            return qgcPal.text
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading:          qsTr("RTK / NTRIP")
        visible:          _ntrip.visible

        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:             qsTr("Enable NTRIP/RTK")
            fact:             _enabled
            visible:          _enabled.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true
        enabled:          _enabled.rawValue
        visible:          _ntrip.ntripServerHostAddress.visible || _ntrip.ntripServerPort.visible ||
                          _ntrip.ntripUsername.visible || _ntrip.ntripPassword.visible ||
                          _ntrip.ntripMountpoint.visible || _ntrip.ntripWhitelist.visible ||
                          _ntrip.ntripUseSpartn.visible

        // 状态行
        QGCLabel {
            Layout.fillWidth: true
            Layout.minimumHeight: 30
            wrapMode: Text.WordWrap
            text: qsTr("Connection status: %1").arg(_statusTextCN())
            color: _statusColor()
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Server Address")
            fact:             _ntrip.ntripServerHostAddress
            visible:          _ntrip.ntripServerHostAddress.visible
            textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 60
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Port")
            fact:             _ntrip.ntripServerPort
            visible:          _ntrip.ntripServerPort.visible
            textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 20
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Username")
            fact:             _ntrip.ntripUsername
            visible:          _ntrip.ntripUsername.visible
            textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 60
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Password")
            fact:             _ntrip.ntripPassword
            visible:          _ntrip.ntripPassword.visible
            textField.echoMode: TextInput.Password
            textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 60
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Mountpoint")
            fact:             _ntrip.ntripMountpoint
            visible:          _ntrip.ntripMountpoint.visible
            textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 40
        }

        // 白名单字段不同项目含义不一：有的是 IP 白名单，有的是“只允许列表”
        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Whitelist (IP/Device)")
            fact:             _ntrip.ntripWhitelist
            visible:          _ntrip.ntripWhitelist.visible
            textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 40
        }

        // 你原来 disabled 了，这里保留：不可用但展示
        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:             qsTr("Use SPARTN (not supported yet)")
            fact:             _ntrip.ntripUseSpartn
            visible:          _ntrip.ntripUseSpartn.visible
            enabled:          false
        }
    }
}
