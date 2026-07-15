import QtQuick

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id:     control
    width:  Math.min(_defaultWidth, _maxWidth)
    height: _outerRadius * 2
    radius: _outerRadius
    color:  qgcPal.window

    property real extraInset:           0
    property real extraValuesWidth:     _outerRadius

    property real   _defaultWidth:      mainWindow.width * 0.2
    property real   _maxWidth:          ScreenTools.defaultFontPixelHeight * 15
    property real   _innerRadius:       (width - (_topBottomMargin * 2)) / 2
    property real   _outerRadius:       _innerRadius + _topBottomMargin
    property real   _topBottomMargin:   (width * 0.05) / 2

    DeadMouseArea { anchors.fill: parent }

    QGCPalette { id: qgcPal }

    QGCCompassWidget {
        id:                     compass
        size:                   control._innerRadius * 2
        vehicle:                globals.activeVehicle
        anchors.centerIn:       parent
    }
}
