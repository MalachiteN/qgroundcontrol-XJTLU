import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

Rectangle {
    width:  ScreenTools.defaultFontPixelHeight * 10
    height: _outerRadius * 2
    radius: _outerRadius
    color:  QGroundControl.globalPalette.window

    property real extraInset:           0
    property real extraValuesWidth:     _outerRadius

    property real _outerMargin: (width * 0.05) / 2
    property real _outerRadius: width / 2
    property real _innerRadius: _outerRadius - _outerMargin

    DeadMouseArea {
        anchors.fill: parent
    }

    QGCCompassWidget {
        anchors.centerIn:   parent
        size:               _innerRadius * 2
        vehicle:            globals.activeVehicle
    }
}
