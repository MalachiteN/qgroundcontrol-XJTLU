import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Rectangle {
    color:          qgcPal.window
    anchors.fill:   parent

    readonly property real _margins: ScreenTools.defaultFontPixelHeight

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    QGCFlickable {
        anchors.fill:   parent
        contentWidth:   column.width  + (_margins * 2)
        contentHeight:  column.height + (_margins * 2)
        clip:           true

        ColumnLayout {
            id:                 column
            anchors.margins:    _margins
            anchors.left:       parent.left
            anchors.top:        parent.top
            spacing:            ScreenTools.defaultFontPixelHeight / 4

            QGCCheckBox {
                id:     sendStatusText
                text:   qsTr("发送状态信息 + 语音播报")
            }

            QGCButton {
                text:               qsTr("启动模拟：PX4 载具")
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startPX4MockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("启动模拟：ArduPilot 多旋翼（ArduCopter）")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduCopterMockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("启动模拟：ArduPilot 固定翼（ArduPlane）")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduPlaneMockLink(sendStatusText.checked)
            }

            // 船/水下更相关：可把“Sub”文案改成“水下/船用（ArduSub）”
            QGCButton {
                text:               qsTr("启动模拟：水下/船用（ArduSub）")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduSubMockLink(sendStatusText.checked)
            }

            // Rover 对船未必准确，但更接近“地面/无人车/通用运动平台”
            QGCButton {
                text:               qsTr("启动模拟：地面/通用平台（ArduRover）")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduRoverMockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("启动模拟：通用载具")
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startGenericMockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("停止一个模拟连接")
                Layout.fillWidth:   true
                onClicked:          QGroundControl.stopOneMockLink()
            }
        }
    }
}
