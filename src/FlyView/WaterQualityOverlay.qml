import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebSockets
import QGroundControl
import QGroundControl.Controls

Item {
    id: _root
    width:  ScreenTools.defaultFontPixelWidth * 30
    height: contentLayout.height + (ScreenTools.defaultFontPixelHeight)
    visible: true // Controlled by parent or setting

    // Configuration
    property string serverIp:   "111.229.242.175"
    property string httpPort:   "11453"
    property string wsPort:     "11452"
    property string stationName: QGroundControl.settingsManager.autoConnectSettings.groundStationName.valueString

    // Internal State
    property string currentBoatName: ""
    property var    sensorData: [] // Array of {name: "PH", value: 7.2}

    // Background
    Rectangle {
        anchors.fill:   parent
        color:          qgcPal.window
        opacity:        0.85
        radius:         ScreenTools.defaultFontPixelWidth / 2
        border.color:   qgcPal.text
        border.width:   1

        QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
    }

    // Main Layout
    ColumnLayout {
        id:                 contentLayout
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.margins:    ScreenTools.defaultFontPixelWidth / 2
        spacing:            ScreenTools.defaultFontPixelHeight / 2

        // Header & Selector
        RowLayout {
            Layout.fillWidth: true
            QGCLabel { 
                text: qsTr("Select USV")
                font.pointSize: ScreenTools.smallFontPointSize
                Layout.alignment: Qt.AlignVCenter
            }
            
            QGCComboBox {
                id: boatSelector
                Layout.fillWidth: true
                model: [qsTr("Click to refresh...")]
                
                onActivated: (index) => {
                    var selected = textAt(index)
                    if (selected === qsTr("Click to refresh...")) {
                        fetchBoatList()
                    } else {
                        connectToBoat(selected)
                    }
                }

                Component.onCompleted: fetchBoatList()
            }

            QGCButton {
                text: qsTr("Refresh")
                onClicked: fetchBoatList()
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: qgcPal.text
            opacity: 0.3
        }

        // Data Grid
        GridLayout {
            columns: 2
            columnSpacing: ScreenTools.defaultFontPixelWidth
            Layout.fillWidth: true
            
            // Empty State
            QGCLabel {
                visible:            sensorData.length === 0
                Layout.columnSpan:  2
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignHCenter
                text:               socket.status === WebSocket.Open ? qsTr("Waiting for data...") : qsTr("Disconnected")
                font.pointSize:     ScreenTools.smallFontPointSize
                opacity:            0.6
            }

            Repeater {
                model: sensorData
                delegate: Item {
                    // Wrapper to fit in GridLayout logic if needed, 
                    // but Repeater in GridLayout adds items directly.
                    // We need to ensure we output 2 items per model entry or wrap them.
                    // GridLayout flow is LeftToRight by default.
                    
                    // Actually, Repeater inside GridLayout doesn't work perfectly for multi-column rows 
                    // unless we use a nested layout or assume 1 item per cell.
                    // Let's use a RowLayout per sensor for simplicity in this constrained environment
                    
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight

                    RowLayout {
                        anchors.fill: parent
                        QGCLabel { 
                            text: modelData.name
                            Layout.fillWidth: true
                            color: qgcPal.text
                        }
                        QGCLabel { 
                            text: String(modelData.value)
                            font.bold: true
                            color: qgcPal.text
                        }
                    }
                }
            }
        }
        
        // Status Bar
        QGCLabel {
            Layout.alignment: Qt.AlignHCenter
            font.pointSize: ScreenTools.smallFontPointSize * 0.8
            text: {
                var statusStr = qsTr("Unknown")
                if (socket.status == WebSocket.Connecting) statusStr = qsTr("Connecting...")
                else if (socket.status == WebSocket.Open) statusStr = qsTr("Online")
                else if (socket.status == WebSocket.Closing) statusStr = qsTr("Closing...")
                else if (socket.status == WebSocket.Closed) statusStr = qsTr("Offline")
                else if (socket.status == WebSocket.Error) statusStr = qsTr("Error")
                return qsTr("Station: %1 | %2").arg(_root.stationName).arg(statusStr)
            }
            opacity: 0.6
        }
    }

    // --- Logic ---

    function fetchBoatList() {
        var xhr = new XMLHttpRequest()
        var url = "http://" + serverIp + ":" + httpPort + "/list?name=" + stationName
        console.log("Fetching boat list from:", url)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var boats = json.boats || []
                        var comboModel = []
                        
                        if (boats.length === 0) {
                            comboModel.push(qsTr("No Boats"))
                        } else {
                            for (var i = 0; i < boats.length; i++) {
                                comboModel.push(boats[i])
                            }
                        }
                        
                        boatSelector.model = comboModel
                        
                        // Auto-select first if available and not connected
                        if (boats.length > 0 && currentBoatName === "") {
                            boatSelector.currentIndex = 0
                            connectToBoat(boats[0])
                        }
                    } catch (e) {
                        console.error("JSON Parse error:", e)
                    }
                } else {
                    console.error("Boat list fetch failed:", xhr.status)
                    boatSelector.model = [qsTr("Connection failed")]
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function connectToBoat(boatName) {
        if (boatName === qsTr("No Boats") || boatName === qsTr("Click to refresh...") || boatName === qsTr("Connection failed")) return
        
        if (currentBoatName !== boatName) {
            currentBoatName = boatName
            socket.active = false
            sensorData = []
            
            // Construct WebSocket URL
            // ws://SERVER_IP:WS_PORT/gcs/{StationName}/{BoatName}
            var url = "ws://" + serverIp + ":" + wsPort + "/gcs/" + stationName + "/" + boatName
            console.log("Connecting WS:", url)
            socket.url = url
            socket.active = true
        }
    }

    WebSocket {
        id: socket
        active: false
        
        onTextMessageReceived: (message) => {
            try {
                var json = JSON.parse(message)
                // Expected format: { "timestamp": ..., "data": [{ "name": "PH", "value": 7.2 }, ...] }
                if (json.data) {
                    // Update model. Assigning to property triggers change signal
                    sensorData = json.data
                }
            } catch (e) {
                console.warn("WS JSON Error:", e)
            }
        }

        onStatusChanged: (status) => {
            if (status == WebSocket.Error) {
                console.error("WS Error:", socket.errorString)
            } else if (status == WebSocket.Open) {
                console.log("WS Connected")
            }
        }
    }
}