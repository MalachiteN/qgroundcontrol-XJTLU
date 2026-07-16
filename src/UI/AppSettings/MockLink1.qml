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
                text:   qsTr("Send status text + voice broadcast")
            }

            QGCButton {
                text:               qsTr("Start Mock: PX4 Vehicle")
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startPX4MockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("Start Mock: ArduPilot Multirotor (ArduCopter)")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduCopterMockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("Start Mock: ArduPilot Fixed Wing (ArduPlane)")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduPlaneMockLink(sendStatusText.checked)
            }

            // 船/水下更相关：可把“Sub”文案改成“水下/船用（ArduSub）”
            QGCButton {
                text:               qsTr("Start Mock: Sub/Boat (ArduSub)")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduSubMockLink(sendStatusText.checked)
            }

            // Rover 对船未必准确，但更接近“地面/无人车/通用运动平台”
            QGCButton {
                text:               qsTr("Start Mock: Ground/General (ArduRover)")
                visible:            QGroundControl.hasAPMSupport
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startAPMArduRoverMockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("Start Mock: Generic Vehicle")
                Layout.fillWidth:   true
                onClicked:          QGroundControl.startGenericMockLink(sendStatusText.checked)
            }

            QGCButton {
                text:               qsTr("Stop one mock link")
                Layout.fillWidth:   true
                onClicked:          QGroundControl.stopOneMockLink()
            }
        }
    }
}
