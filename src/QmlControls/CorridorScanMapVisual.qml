import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

/// Corridor Scan Complex Mission Item visuals
TransectStyleMapVisuals {
    polygonInteractive: false

    property bool _currentItem: object.isCurrentItem

    QGCMapPolylineVisuals {
        id:             mapPolylineVisuals
        mapControl:     map
        mapPolyline:    object.corridorPolyline
        interactive:    _currentItem && parent.interactive
        lineWidth:      3
        lineColor:      "#00a8a8"
        visible:        _currentItem
        opacity:        parent.opacity
    }
}
