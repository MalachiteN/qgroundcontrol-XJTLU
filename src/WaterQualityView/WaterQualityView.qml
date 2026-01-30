import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.WaterQualityView

Item {
    id: _root
    anchors.fill: parent

    // Configuration
    property string serverIp:   "111.229.242.175"
    property string httpPort:   "11453"
    property string wsPort:     "11452"
    property string stationName: QGroundControl.settingsManager.autoConnectSettings.groundStationName.valueString

    // Map<Name, LineSeries>
    property var seriesMap: ({}) 
    
    // Palette
    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
    
    // Colors for new lines
    property var _colors: ["#00E04B","#DE8500","#F32836","#BFBFBF","#536DFF","#EECC44", "#00A3E0", "#A044FF"]

    // Model for checkboxes
    ListModel { id: sensorTypesModel }

    onStationNameChanged: {
        WaterQualityManager.setServerConfig(serverIp, wsPort, stationName)
        refreshBoatList()
    }

    Component.onCompleted: {
        WaterQualityManager.setServerConfig(serverIp, wsPort, stationName)
        refreshBoatList()
        // Restore view state from singleton
        syncSensorList()
        syncAxis()
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color:        qgcPal.window
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- Toolbar ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3
            color: qgcPal.toolbarBackground
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth
                spacing: ScreenTools.defaultFontPixelWidth

                QGCLabel { 
                    text: qsTr("选择显示或隐藏的数据条目 ↓")
                    font.pointSize: ScreenTools.largeFontPointSize
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true } // Spacer

                QGCLabel { 
                    text: qsTr("选择无人船 →  ")
                    font.pointSize: ScreenTools.largeFontPointSize
                    font.bold: true
                }
                
                QGCLabel { text: qsTr("无人船名称:") }
                QGCComboBox {
                    id: boatSelector
                    Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 15
                    model: ["Click Refresh..."]
                    onActivated: (index) => {
                        var val = textAt(index)
                        if(val !== "Click Refresh..." && val !== "No Boats") {
                            WaterQualityManager.connectToBoat(val)
                            resetChart()
                        }
                    }
                }
                QGCButton {
                    text: qsTr("刷新")
                    onClicked: refreshBoatList()
                }
            }
        }

        // --- Control Panel (Legend & Toggles) ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
            color: qgcPal.windowShade

            ScrollView {
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth / 2
                clip: true

                Row {
                    spacing: ScreenTools.defaultFontPixelWidth * 2
                    
                    Repeater {
                        model: sensorTypesModel
                        delegate: Row {
                            spacing: ScreenTools.defaultFontPixelWidth / 2
                            
                            Rectangle {
                                width: ScreenTools.defaultFontPixelHeight
                                height: width
                                color: "transparent"
                                border.color: model.checked ? model.colorCode : qgcPal.text
                                border.width: 1
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: parent.height * 0.6
                                    color: model.colorCode
                                    visible: model.checked
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: toggleSeries(index)
                                }
                            }
                            
                            QGCLabel {
                                text: model.name
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: toggleSeries(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Chart ---
        ChartView {
            id: chart
            Layout.fillWidth: true
            Layout.fillHeight: true
            theme: ChartView.ChartThemeDark
            antialiasing: true
            legend.visible: false
            backgroundColor: qgcPal.window
            
            ValueAxis {
                id: axisX
                min: 0
                max: 60
                labelFormat: "%.0fs"
                titleText: "Time (s)"
                labelsColor: qgcPal.text
                gridLineColor: qgcPal.text
            }
            
            ValueAxis {
                id: axisY
                min: 0
                max: 10
                titleText: "Value"
                labelsColor: qgcPal.text
                gridLineColor: qgcPal.text
            }
        }
    }

    // --- Logic ---

    Connections {
        target: WaterQualityManager
        
        function onCurrentBoatNameChanged() {
            // Sync combo box if needed
            var name = WaterQualityManager.currentBoatName
            var idx = boatSelector.find(name)
            if (idx >= 0) boatSelector.currentIndex = idx
        }

        function onSensorListChanged() {
            syncSensorList()
        }

        function onAxisRangeChanged() {
           syncAxis()
        }

        function onNewDataPoint(name, x, y) {
            // console.log("New Data:", name, x, y)
            // Add to series
            if (seriesMap[name]) {
                seriesMap[name].append(x, y)
                // Scroll X
                if (x > axisX.max) {
                    var diff = x - axisX.max
                    axisX.min += diff
                    axisX.max += diff
                }
            }
        }
    }
    
    function syncAxis() {
        axisY.min = WaterQualityManager.yAxisMin
        axisY.max = WaterQualityManager.yAxisMax
    }

    function syncSensorList() {
        var list = WaterQualityManager.sensorList
        // Add missing sensors
        for (var i = 0; i < list.length; i++) {
            var name = list[i]
            if (!seriesMap[name]) {
                createSeriesFor(name)
            }
        }
        
        // Ensure series visibility matches manager
        for (var sName in seriesMap) {
             var visible = WaterQualityManager.isSensorVisible(sName)
             seriesMap[sName].visible = visible
             
             // Sync Checkbox
             for(var j=0; j<sensorTypesModel.count; j++) {
                 if(sensorTypesModel.get(j).name === sName) {
                     sensorTypesModel.setProperty(j, "checked", visible)
                     break
                 }
             }
        }
    }

    function createSeriesFor(name) {
        // Assign color deterministically based on name hash or index
        // Simple index based for now (risk of color shift on reload if order changes)
        // Better: hash string to index
        var code = 0;
        for(var i=0; i<name.length; i++) code += name.charCodeAt(i);
        var color = _colors[code % _colors.length]

        var series = chart.createSeries(ChartView.SeriesTypeLine, name, axisX, axisY)
        series.color = color
        series.width = 2
        seriesMap[name] = series
        
        sensorTypesModel.append({
            "name": name,
            "colorCode": color,
            "checked": WaterQualityManager.isSensorVisible(name)
        })
        
        // Restore history
        var hist = WaterQualityManager.getHistory(name)
        if (hist) {
            // QList<QPointF> converts to array of points
            // series.append takes x, y. Can we append array? No in QML ChartView usually loop.
            // Or replace.
            // Optimization: replace data if large history
            series.removePoints(0, series.count)
            for (var k=0; k<hist.length; k++) {
                series.append(hist[k].x, hist[k].y)
            }
        }
    }

    function toggleSeries(index) {
        var item = sensorTypesModel.get(index)
        var newVal = !item.checked
        // Update UI immediately for responsiveness
        sensorTypesModel.setProperty(index, "checked", newVal)
        
        // Update series visibility immediately
        if (seriesMap[item.name]) {
            seriesMap[item.name].visible = newVal
        }

        // Notify Manager (which triggers recalc range -> signal axisRangeChanged)
        WaterQualityManager.setSensorVisible(item.name, newVal)
    }
    
    function resetChart() {
        chart.removeAllSeries()
        sensorTypesModel.clear()
        seriesMap = {}
        axisX.min = 0
        axisX.max = 60
    }
    
    function refreshBoatList() {
        var xhr = new XMLHttpRequest()
        var url = "http://" + serverIp + ":" + httpPort + "/list?name=" + stationName
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    var boats = json.boats || []
                    boatSelector.model = boats.length ? boats : ["No Boats"]
                    // Auto-select if manager has boat
                    var current = WaterQualityManager.currentBoatName
                    if (current && boats.indexOf(current) !== -1) {
                        boatSelector.currentIndex = boats.indexOf(current)
                    } else if (boats.length > 0) {
                        // Auto-connect to first boat
                        console.log("Auto-connecting to first boat:", boats[0])
                        boatSelector.currentIndex = 0
                        WaterQualityManager.connectToBoat(boats[0])
                        resetChart()
                    }
                } catch (e) {}
            }
        }
        xhr.open("GET", url); xhr.send()
    }
}