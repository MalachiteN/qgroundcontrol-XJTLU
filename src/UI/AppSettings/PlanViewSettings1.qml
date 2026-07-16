import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    property var _settingsManager:  QGroundControl.settingsManager
    property var _planViewSettings: QGroundControl.settingsManager.planViewSettings

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading: qsTr("Plan View")

        // 飞机/高度专用：船用不显示
        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Default Mission Altitude")
            fact:               _settingsManager.appSettings.defaultMissionItemAltitude
            visible:            false
        }

        // VTOL 专用：船用不显示
        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("VTOL TransitionDistance")
            fact:               _planViewSettings.vtolTransitionDistance
            visible:            false
        }

        // 生成航线/图案时是否使用 CONDITION_GATE（如果你们船用任务也支持，可保留）
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Use MAV_CMD_CONDITION_GATE for pattern generation")
            fact:               _planViewSettings.useConditionGate
            visible:            fact.visible
        }

        // 起飞条目（飞机专用）：船用不显示
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Missions do not require takeoff item")
            fact:               _planViewSettings.takeoffItemNotRequired
            visible:            false
        }

        // 多段降落（飞机专用）：船用不显示
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Allow configuring multiple landing sequences")
            fact:               _planViewSettings.allowMultipleLandingPatterns
            visible:            false
        }
    }
}
