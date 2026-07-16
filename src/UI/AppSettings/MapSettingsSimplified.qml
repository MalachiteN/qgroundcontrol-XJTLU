import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.QGCMapEngineManager

Item {
    id: root

    property var    _settingsManager:               QGroundControl.settingsManager
    property var    _appSettings:                   _settingsManager.appSettings
    property var    _mapsSettings:                  _settingsManager.mapsSettings
    property var    _mapEngineManager:              QGroundControl.mapEngineManager
    property bool   _currentlyImportOrExporting:    _mapEngineManager.importAction === QGCMapEngineManager.ImportAction.ActionExporting || _mapEngineManager.importAction === QGCMapEngineManager.ImportAction.ActionImporting
    property real   _largeTextFieldWidth:           ScreenTools.defaultFontPixelWidth * 30

    // 保留原本的Fact引用，用于后台逻辑
    property Fact   _mapProviderFact:       _settingsManager.flightMapSettings.mapProvider
    property Fact   _mapTypeFact:           _settingsManager.flightMapSettings.mapType
    property Fact   _elevationProviderFact: _settingsManager.flightMapSettings.elevationMapProvider
    property Fact   _customURLFact:         _settingsManager ? _settingsManager.appSettings.customURL : null
    property Fact   _customURLIPFact:       _settingsManager ? _settingsManager.appSettings.customURLIP : null
    property Fact   _customURLPortFact:     _settingsManager ? _settingsManager.appSettings.customURLPort : null

    function updateCustomURL() {
        if (_customURLFact && _customURLIPFact && _customURLPortFact) {
            var ip = _customURLIPFact.rawValue.toString()
            var port = _customURLPortFact.rawValue.toString()
            _customURLFact.rawValue = "http://" + ip + ":" + port + "/tianditu/hybrid/{z}/{x}/{y}"
        }
    }

    Connections {
        target: _customURLIPFact
        function onRawValueChanged() { updateCustomURL() }
    }

    Connections {
        target: _customURLPortFact
        function onRawValueChanged() { updateCustomURL() }
    }

    // 其他不用的Fact可以保留引用以防报错，或者直接根据需要删除，这里保留以保证兼容性
    property Fact   _tiandituFac:       _settingsManager ? _settingsManager.appSettings.tiandituToken : null
    property Fact   _mapboxFact:        _settingsManager ? _settingsManager.appSettings.mapboxToken : null
    property Fact   _mapboxAccountFact: _settingsManager ? _settingsManager.appSettings.mapboxAccount : null
    property Fact   _mapboxStyleFact:   _settingsManager ? _settingsManager.appSettings.mapboxStyle : null
    property Fact   _esriFact:          _settingsManager ? _settingsManager.appSettings.esriToken : null
    property Fact   _vworldFact:        _settingsManager ? _settingsManager.appSettings.vworldToken : null

    SettingsPage {
        id:           settingsPage
        anchors.fill: parent

        Component.onCompleted: {
            QGroundControl.mapEngineManager.loadTileSets()

                        // [关键修改]
            // 初始化时强制设定为 CustomURL 模式并锁定你的专有地图链接
            // 确保用户打开此页面或程序启动时，地图源被指向你的私有服务
            _mapProviderFact.rawValue = "CustomURL"
            // 设置固定 URL
            root.updateCustomURL()

            // 自动修正 MapType，防止因为之前的设置导致类型不匹配
            var types = _mapEngineManager.mapTypeList("CustomURL")
            if (types.length > 0) {
                 // 通常 CustomURL 只有一个类型 "Custom" 或类似的
                _mapTypeFact.rawValue = types[0]
            }
        }

        Connections {
            target:                 _mapEngineManager
            function onErrorMessageChanged() { errorDialogComponent.createObject(mainWindow).open() }
        }

                // 0. 私有地图服务设置
        SettingsGroupLayout {
            Layout.fillWidth: true
            heading: qsTr("Custom Map URL")

            LabelledFactTextField {
                label: qsTr("Server URL")
                fact: _customURLIPFact
                textFieldPreferredWidth:    _largeTextFieldWidth
            }

            LabelledFactTextField {
                label: qsTr("Port")
                fact: _customURLPortFact
                textFieldPreferredWidth:    _largeTextFieldWidth
            }
        }

        // 1. 地图与高程设置组
        SettingsGroupLayout {
            Layout.fillWidth: true

            // [修改] 移除了 Provider 和 Type 的选择框
            // 只保留高程数据提供商选择
            LabelledComboBox {
                label: qsTr("Elevation Provider")
                model: _mapEngineManager.elevationProviderList

                onActivated: (index) => { _elevationProviderFact.rawValue = comboBox.textAt(index) }

                Component.onCompleted: {
                    var index = comboBox.find(_elevationProviderFact.rawValue)
                    if (index < 0) index = 0
                    comboBox.currentIndex = index
                }
            }
        }

        // 2. 离线地图设置组 (保持原样)
        SettingsGroupLayout {
            Layout.fillWidth:   true
            heading:            qsTr("Offline Maps")
            headingDescription: qsTr("Download map tiles for use when offline")

            Repeater {
                model: QGroundControl.mapEngineManager.tileSets

                OfflineMapInfo {
                    tileSet:    object
                    enabled:    !object.deleting
                    onClicked:  offlineMapEditorComponent.createObject(root, { tileSet: object }).showInfo()
                }
            }

            LabelledButton {
                label:      qsTr("Add New Set")
                buttonText: qsTr("Add")
                enabled:    !_currentlyImportOrExporting
                onClicked:  offlineMapEditorComponent.createObject(root).addNewSet()
            }

            LabelledButton {
                label:      qsTr("Import Map Tiles")
                buttonText: qsTr("Import")
                visible:    QGroundControl.corePlugin.options.showOfflineMapImport
                enabled:    !_currentlyImportOrExporting
                onClicked: {
                    _mapEngineManager.importAction = QGCMapEngineManager.ImportAction.ActionNone
                    importDialogComponent.createObject(mainWindow).open()
                }
            }

            LabelledButton {
                label:      qsTr("Export Map Tiles")
                buttonText: qsTr("Export")
                visible:    QGroundControl.corePlugin.options.showOfflineMapExport
                enabled:    !_currentlyImportOrExporting
                onClicked:  exportDialogComponent.createObject(mainWindow).open()
            }

            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                visible: _currentlyImportOrExporting

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               _mapEngineManager.importAction === QGCMapEngineManager.ImportAction.ActionExporting ? qsTr("Exporting") : qsTr("Importing")
                    font.bold:          true
                }
                ProgressBar {
                    width:          ScreenTools.defaultFontPixelWidth * 25
                    from:           0
                    to:             100
                    value:          _mapEngineManager.actionProgress
                }
            }
        }

        // [修改] 移除了 Token 设置组
        // [修改] 移除了 Mapbox 登录组
        // [修改] 移除了 Custom Map URL 输入组

        // 3. 缓存设置组 (保持原样)
        SettingsGroupLayout {
            Layout.fillWidth:   true
            heading:            qsTr("Tile Cache")

            LabelledFactTextField {
                fact: _mapsSettings.maxCacheDiskSize
            }

            LabelledFactTextField {
                fact: _mapsSettings.maxCacheMemorySize
            }
        }

        // [以下对话框组件逻辑保持不变，用于支持离线地图功能]
        QGCFileDialog {
            id:             fileDialog
            folder:         _appSettings.missionSavePath
            nameFilters:    [ qsTr("Tile Sets (*.%1)").arg(defaultSuffix) ]
            defaultSuffix:  _appSettings.tilesetFileExtension

            onAcceptedForSave: (file) => {
                close()
                _mapEngineManager.exportSets(file)
            }

            onAcceptedForLoad: (file) => {
                close()
                _mapEngineManager.importSets(file)
            }
        }

        Component {
            id: exportDialogComponent

            QGCPopupDialog {
                title:      qsTr("Export Selected Tile Sets")
                buttons:    Dialog.Ok | Dialog.Cancel

                onAccepted: {
                    close()
                    fileDialog.title = qsTr("Export Tiles")
                    fileDialog.openForSave()
                }

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    Repeater {
                        model: _mapEngineManager.tileSets

                        QGCCheckBox {
                            text:       object.name
                            checked:    object.selected
                            onClicked:  object.selected = checked
                        }
                    }
                }
            }
        }

        Component {
            id: importDialogComponent

            QGCPopupDialog {
                title:      qsTr("Import TileSets")
                buttons:    Dialog.Ok | Dialog.Cancel

                onAccepted: {
                    close()
                    fileDialog.title = qsTr("Import Tiles")
                    fileDialog.openForLoad()
                }

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    QGCRadioButton {
                        text:           qsTr("Append to existing sets")
                        checked:        !_mapEngineManager.importReplace
                        onClicked:      _mapEngineManager.importReplace = !checked
                    }
                    QGCRadioButton {
                        text:           qsTr("Replace existing sets")
                        checked:        _mapEngineManager.importReplace
                        onClicked:      _mapEngineManager.importReplace = checked
                    }
                }
            }
        }

        Component {
            id: errorDialogComponent

            QGCSimpleMessageDialog {
                title:      qsTr("Error Message")
                text:       _mapEngineManager.errorMessage
                buttons:    Dialog.Close
            }
        }
    }

    Component {
        id: offlineMapEditorComponent

        OfflineMapEditor {
            id:             offlineMapEditor
            anchors.fill:   parent
        }
    }
}
