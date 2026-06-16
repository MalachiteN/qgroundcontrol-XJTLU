import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap

// To implement a custom overlay copy this code to your own control in your custom code source. Then override the
// FlyViewCustomLayer.qml resource with your own qml. See the custom example and documentation for details.
Item {
    id: _root

    property var parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _toolInsets // These are the insets for your custom overlay additions
    property var mapControl

    // since this file is a placeholder for the custom layer in a standard build, we will just pass through the parent insets
        QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    Rectangle {
        id:                 waterQualityDisplay
        anchors.left:       parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
        width:              waterColumn.width + (ScreenTools.defaultFontPixelWidth * 2)
        height:             waterColumn.height + (ScreenTools.defaultFontPixelHeight)
        radius:             ScreenTools.defaultFontPixelWidth / 2
        color:              Qt.rgba(0, 0, 0, 0.5)
        visible:            _activeVehicle

        property var subInfo: _activeVehicle && _activeVehicle.factGroups.apmSubInfo ? _activeVehicle.factGroups.apmSubInfo : null

        ColumnLayout {
            id:                 waterColumn
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelHeight / 4

            QGCLabel {
                text: "PH值: " + (waterQualityDisplay.subInfo ? waterQualityDisplay.subInfo.watPH.valueString : "0")
                color: "white"
            }
            QGCLabel {
                text: "水温: " + (waterQualityDisplay.subInfo ? waterQualityDisplay.subInfo.watTemp.valueString : "0")
                color: "white"
            }
            QGCLabel {
                text: "浊度: " + (waterQualityDisplay.subInfo ? waterQualityDisplay.subInfo.watTurb.valueString : "0")
                color: "white"
            }
            QGCLabel {
                text: "电导率: " + (waterQualityDisplay.subInfo ? waterQualityDisplay.subInfo.watCond.valueString : "0")
                color: "white"
            }
        }
    }
}
