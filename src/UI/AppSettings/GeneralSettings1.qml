import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    // -------------------------
    // Settings references
    // -------------------------
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath

    // Units facts
    property var  _units:       _settingsManager.unitsSettings
    property Fact _hDistUnits:  _units.horizontalDistanceUnits
    property Fact _vDistUnits:  _units.verticalDistanceUnits
    property Fact _areaUnits:   _units.areaUnits
    property Fact _speedUnits:  _units.speedUnits
    property Fact _tempUnits:   _units.temperatureUnits

    // -------------------------
    // HARD LOCK VALUES (MUST start with lower-case in QML)
    // -------------------------
    readonly property string lockLang:   "zh_CN"   // 改成你们实际 rawValue
    readonly property string lockDist:   "m"
    readonly property string lockArea:   "m²"      // 若你们是 "sqm"/"Square meters" 改这里
    readonly property string lockTemp:   "°C"      // 若你们是 "Celsius" 改这里

    // Speed allowed values (two choices only)
    readonly property string speedMs:   "m/s"
    readonly property string speedKmh:  "km/h"

    // -------------------------
    // Hard-lock logic
    // -------------------------
    function applyLocks() {
        // Language hard lock
        if (_appSettings && _appSettings.qLocaleLanguage) {
            if (_appSettings.qLocaleLanguage.rawValue !== lockLang) {
                _appSettings.qLocaleLanguage.rawValue = lockLang
            }
        }

        // Units hard lock
        if (_hDistUnits && _hDistUnits.rawValue !== lockDist) _hDistUnits.rawValue = lockDist
        if (_vDistUnits && _vDistUnits.rawValue !== lockDist) _vDistUnits.rawValue = lockDist
        if (_areaUnits  && _areaUnits.rawValue  !== lockArea) _areaUnits.rawValue  = lockArea
        if (_tempUnits  && _tempUnits.rawValue  !== lockTemp) _tempUnits.rawValue  = lockTemp

        // Speed: only allow m/s or km/h
        if (_speedUnits) {
            var v = _speedUnits.rawValue
            if (v !== speedMs && v !== speedKmh) {
                _speedUnits.rawValue = speedMs
            }
        }
    }

    Component.onCompleted: applyLocks()

    // 双保险：彻底写死（除了速度两选）
    Timer {
        interval: 400
        repeat: true
        running: true
        onTriggered: applyLocks()
    }

    Connections {
        target: _appSettings ? _appSettings.qLocaleLanguage : null
        function onRawValueChanged() {
            if (_appSettings.qLocaleLanguage.rawValue !== lockLang) {
                _appSettings.qLocaleLanguage.rawValue = lockLang
            }
        }
    }
    Connections { target: _hDistUnits; function onRawValueChanged() { if (_hDistUnits.rawValue !== lockDist) _hDistUnits.rawValue = lockDist } }
    Connections { target: _vDistUnits; function onRawValueChanged() { if (_vDistUnits.rawValue !== lockDist) _vDistUnits.rawValue = lockDist } }
    Connections { target: _areaUnits;  function onRawValueChanged() { if (_areaUnits.rawValue  !== lockArea) _areaUnits.rawValue  = lockArea } }
    Connections { target: _tempUnits;  function onRawValueChanged() { if (_tempUnits.rawValue  !== lockTemp) _tempUnits.rawValue  = lockTemp } }

    Connections {
        target: _speedUnits
        function onRawValueChanged() {
            if (_speedUnits.rawValue !== speedMs && _speedUnits.rawValue !== speedKmh) {
                _speedUnits.rawValue = speedMs
            }
        }
    }

    // =========================================================
    // 通用
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("General")

        QGCLabel {
            Layout.fillWidth: true
            text: qsTr("Language: Chinese ")
        }

        LabelledFactComboBox {
            label:      qsTr("Color Scheme")
            fact:       _appSettings.indoorPalette
            indexModel: false
            visible:    _appSettings.indoorPalette.visible
        }

        LabelledFactComboBox {
            label:      qsTr("Stream GCS Position")
            fact:       _appSettings.followTarget
            indexModel: false
            visible:    _appSettings.followTarget.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:           qsTr("Mute all audio output")
            fact:           _audioMuted
            visible:        _audioMuted.visible
            property Fact _audioMuted: _appSettings.audioMuted
        }

        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:       qsTr("Android: Don't save to SD card")
            fact:       _appSettings.androidDontSaveToSDCard
            visible:    fact.visible
        }

        QGCCheckBoxSlider {
            Layout.fillWidth: true
            text:       qsTr("Clear all settings on next start")
            checked:    false
            onClicked: {
                if (checked) {
                    QGroundControl.deleteAllSettingsNextBoot()
                } else {
                    QGroundControl.clearDeleteAllSettingsNextBoot()
                }
            }
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _appFontPointSize.visible

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("UI Scaling")
            }

            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth * 2

                QGCButton {
                    Layout.preferredWidth:  height
                    height:                 baseFontEdit.height * 1.5
                    text:                   "-"
                    onClicked: {
                        if (_appFontPointSize.value > _appFontPointSize.min) {
                            _appFontPointSize.value = _appFontPointSize.value - 1
                        }
                    }
                }

                QGCLabel {
                    id:                     baseFontEdit
                    width:                  ScreenTools.defaultFontPixelWidth * 6
                    text:                   (QGroundControl.settingsManager.appSettings.appFontPointSize.value / ScreenTools.platformFontPointSize * 100).toFixed(0) + "%"
                }

                QGCButton {
                    Layout.preferredWidth:  height
                    height:                 baseFontEdit.height * 1.5
                    text:                   "+"
                    onClicked: {
                        if (_appFontPointSize.value < _appFontPointSize.max) {
                            _appFontPointSize.value = _appFontPointSize.value + 1
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _appSavePath.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            0

                QGCLabel { text: qsTr("Application Load/Save Path") }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                    elide:              Text.ElideMiddle
                }
            }

            QGCButton {
                text:       qsTr("Browse")
                onClicked:  savePathBrowseDialog.openForLoad()

                QGCFileDialog {
                    id:                 savePathBrowseDialog
                    title:              qsTr("Choose the location to save/load files")
                    folder:             _appSavePath.rawValue
                    selectFolder:       true
                    onAcceptedForLoad:  (file) => _appSavePath.rawValue = file
                }
            }
        }
    }

    // =========================================================
    // 单位（除速度外全部锁死）
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Units")
        visible:            _units.visible

        QGCLabel { Layout.fillWidth: true; text: qsTr("Horizontal Distance: m") }
        QGCLabel { Layout.fillWidth: true; text: qsTr("Vertical Distance: m") }
        QGCLabel { Layout.fillWidth: true; text: qsTr("Area: m²") }
        QGCLabel { Layout.fillWidth: true; text: qsTr("Temperature: °C") }

        RowLayout {
            Layout.fillWidth: true
            spacing: ScreenTools.defaultFontPixelWidth * 2
            visible: _speedUnits && _speedUnits.visible

            QGCLabel {
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 16
                text: qsTr("Speed Unit")
            }

            QGCComboBox {
                id: speedCombo
                Layout.fillWidth: true
                model: [ "m/s", "km/h" ]

                Component.onCompleted: {
                    if (_speedUnits && _speedUnits.rawValue === speedKmh) currentIndex = 1
                    else currentIndex = 0
                }

                onActivated: {
                    if (!_speedUnits) return
                    _speedUnits.rawValue = (currentIndex === 1) ? speedKmh : speedMs
                }
            }
        }

        QGCLabel {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.75
            text: qsTr("Note: Distance/area/temperature are fixed to metric units; speed supports only m/s and km/h.")
        }
    }

    // =========================================================
    // 品牌图片
    // =========================================================
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Brand Image")
        visible:            _brandImageSettings.visible && !ScreenTools.isMobile

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _userBrandImageIndoor.visible

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            0

                QGCLabel { Layout.fillWidth: true; text: qsTr("Indoor Image") }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageIndoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    visible:            _userBrandImageIndoor.valueString.length > 0
                }
            }

            QGCButton {
                text:       qsTr("Browse")
                onClicked:  userBrandImageIndoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id:                 userBrandImageIndoorBrowseDialog
                    title:              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageIndoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageIndoor.rawValue = "file:///" + file
                }
            }
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _userBrandImageOutdoor.visible

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            0

                QGCLabel { Layout.fillWidth: true; text: qsTr("Outdoor Image") }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageOutdoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    visible:            _userBrandImageOutdoor.valueString.length > 0
                }
            }

            QGCButton {
                text:       qsTr("Browse")
                onClicked:  userBrandImageOutdoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id:                 userBrandImageOutdoorBrowseDialog
                    title:              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageOutdoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageOutdoor.rawValue = "file:///" + file
                }
            }
        }

        LabelledButton {
            label:      qsTr("Reset Images")
            buttonText: qsTr("Reset")
            onClicked:  {
                _userBrandImageIndoor.rawValue = ""
                _userBrandImageOutdoor.rawValue = ""
            }
        }
    }
}
