import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    property var    _settingsManager:            QGroundControl.settingsManager
    property var    _videoManager:              QGroundControl.videoManager
    property var    _videoSettings:             _settingsManager.videoSettings
    property string _videoSource:               _videoSettings.videoSource.rawValue
    property bool   _isGST:                     _videoManager.gstreamerEnabled
    property bool   _isStreamSource:            _videoManager.isStreamSource
    property bool   _isUDP264:                  _isStreamSource && (_videoSource === _videoSettings.udp264VideoSource)
    property bool   _isUDP265:                  _isStreamSource && (_videoSource === _videoSettings.udp265VideoSource)
    property bool   _isRTSP:                    _isStreamSource && (_videoSource === _videoSettings.rtspVideoSource)
    property bool   _isTCP:                     _isStreamSource && (_videoSource === _videoSettings.tcpVideoSource)
    property bool   _isMPEGTS:                  _isStreamSource && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool   _videoAutoStreamConfig:     _videoManager.autoStreamConfigured
    property bool   _videoSourceDisabled:       _videoSource === _videoSettings.disabledVideoSource
    property real   _urlFieldWidth:             ScreenTools.defaultFontPixelWidth * 40
    property bool   _requiresUDPUrl:            _isUDP264 || _isUDP265 || _isMPEGTS

    property var    _autoConnectSettings:       QGroundControl.settingsManager.autoConnectSettings
    property string _groundStationName:         _autoConnectSettings.groundStationName.valueString
    property string _relayServerHost:           _autoConnectSettings.groundStationStatusHost.valueString

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Video Source")
        headingDescription: _videoAutoStreamConfig ? qsTr("Mavlink camera stream is automatically configured") : ""
        enabled:            !_videoAutoStreamConfig

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Source")
            indexModel:         false
            fact:               _videoSettings.videoSource
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Connection")
        // 修正：把 | 改成 ||
        visible:            !_videoSourceDisabled && !_videoAutoStreamConfig && (_isTCP || _isRTSP || _requiresUDPUrl)

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    _urlFieldWidth
            label:                      qsTr("RTSP URL")
            fact:                       _videoSettings.rtspUrl
            visible:                    _isRTSP && _videoSettings.rtspUrl.visible
        }

        RowLayout {
            Layout.fillWidth:   true
            visible:            _isRTSP && _videoSettings.rtspUrl.visible

            QGCLabel {
                text:           qsTr("USV")
                font.pointSize: ScreenTools.defaultFontPointSize
                Layout.alignment: Qt.AlignVCenter
            }

            QGCComboBox {
                id:             boatSelector
                Layout.fillWidth: true
                model:          [qsTr("Click to refresh...")]

                onActivated: (index) => {
                    var selected = textAt(index)
                    if (selected === qsTr("Click to refresh...")) {
                        fetchBoatList()
                    } else if (selected !== qsTr("No USVs online") && selected !== qsTr("Connection failed") && selected !== qsTr("Please configure ground station connection first") && selected !== qsTr("Parse failed")) {
                        setRtspUrlForBoat(selected)
                    }
                }
            }

            QGCButton {
                text:       qsTr("Refresh")
                onClicked:  fetchBoatList()
            }
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            label:                      qsTr("TCP URL")
            textFieldPreferredWidth:    _urlFieldWidth
            fact:                       _videoSettings.tcpUrl
            visible:                    _isTCP && _videoSettings.tcpUrl.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    _urlFieldWidth
            label:                      qsTr("UDP URL")
            fact:                       _videoSettings.udpUrl
            visible:                    _requiresUDPUrl && _videoSettings.udpUrl.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Settings")
        visible:            !_videoSourceDisabled

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Aspect Ratio")
            fact:               _videoSettings.aspectRatio
            visible:            !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
        }

        // 原文“disarmed”是飞行语义，这里改成更通用的“未启用/未连接时停止录制”
        // 如果你们业务是“未解锁/未上电”，可再改词
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Stop recording when disarmed")
            fact:               _videoSettings.disableWhenDisarmed
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Low Latency Mode")
            fact:               _videoSettings.lowLatencyMode
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible && _isGST
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Force Video Decoder")
            fact:               _videoSettings.forceVideoDecoder
            visible:            fact.visible
            indexModel:         false
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading:          qsTr("Local Video Storage")

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Record File Format")
            fact:               _videoSettings.recordingFormat
            visible:            _videoSettings.recordingFormat.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Auto-Delete Saved Recordings")
            fact:               _videoSettings.enableStorageLimit
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Max Storage Usage")
            fact:               _videoSettings.maxVideoSize
            visible:            fact.visible
            enabled:            _videoSettings.enableStorageLimit.rawValue
        }
    }

    function fetchBoatList() {
        if (!_relayServerHost || !_groundStationName) {
            boatSelector.model = [qsTr("Please configure ground station connection first")]
            return
        }

        var xhr = new XMLHttpRequest()
        var url = "http://" + _relayServerHost + ":11454/list?name=" + _groundStationName
        console.log("Fetching boat list from:", url)

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var boats = json.boats || []
                        var comboModel = []

                        if (boats.length === 0) {
                            comboModel.push(qsTr("No USVs online"))
                        } else {
                            for (var i = 0; i < boats.length; i++) {
                                comboModel.push(boats[i])
                            }
                        }

                        boatSelector.model = comboModel
                    } catch (e) {
                        console.error("JSON Parse error:", e)
                        boatSelector.model = [qsTr("Parse failed")]
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

    function setRtspUrlForBoat(boatName) {
        _videoSettings.rtspUrl.value = "rtsp://" + _relayServerHost + ":8554/" + _groundStationName + "/" + boatName
    }
}
