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
        heading: qsTr("任务规划（船用）")

        // 飞机/高度专用：船用不显示
        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("默认任务高度")
            fact:               _settingsManager.appSettings.defaultMissionItemAltitude
            visible:            false
        }

        // VTOL 专用：船用不显示
        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("VTOL 转换距离")
            fact:               _planViewSettings.vtolTransitionDistance
            visible:            false
        }

        // 生成航线/图案时是否使用 CONDITION_GATE（如果你们船用任务也支持，可保留）
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("航线/图案生成时使用 MAV_CMD_CONDITION_GATE")
            fact:               _planViewSettings.useConditionGate
            visible:            fact.visible
        }

        // 起飞条目（飞机专用）：船用不显示
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("任务不需要起飞条目")
            fact:               _planViewSettings.takeoffItemNotRequired
            visible:            false
        }

        // 多段降落（飞机专用）：船用不显示
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("允许配置多个降落序列")
            fact:               _planViewSettings.allowMultipleLandingPatterns
            visible:            false
        }
    }
}
