import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsPage {
    property var _linkManager:          QGroundControl.linkManager
    property var _autoConnectSettings:  QGroundControl.settingsManager.autoConnectSettings

    SettingsGroupLayout {
        heading:        qsTr("自动连接")
        visible:        _autoConnectSettings.visible

        Repeater {
            id: autoConnectRepeater

            model: [
                _autoConnectSettings.autoConnectPixhawk,
                _autoConnectSettings.autoConnectSiKRadio,
                _autoConnectSettings.autoConnectLibrePilot,
                _autoConnectSettings.autoConnectUDP,
                _autoConnectSettings.autoConnectZeroConf,
                _autoConnectSettings.autoConnectRTKGPS,
            ]

            // 专有名词保留英文，但加中文含义更适合船端用户
            property var names: [
                qsTr("Pixhawk（飞控/控制器）"),
                qsTr("SiK Radio（数传电台）"),
                qsTr("LibrePilot"),
                qsTr("UDP（网络广播）"),
                qsTr("Zero-Conf（自动发现）"),
                qsTr("RTK（高精度定位）")
            ]

            FactCheckBoxSlider {
                Layout.fillWidth:   true
                text:               autoConnectRepeater.names[index]
                fact:               modelData
                visible:            modelData.visible
            }
        }
    }

    SettingsGroupLayout {
        heading: qsTr("外置 GPS（NMEA）")
        visible: QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.visible &&
                 QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.visible

        LabelledComboBox {
            id: nmeaPortCombo
            label: qsTr("设备")

            model: ListModel {}

            onActivated: (index) => {
                if (index !== -1) {
                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = comboBox.textAt(index)
                }
            }

            Component.onCompleted: {
                var model = []

                model.push(qsTr("禁用"))
                model.push(qsTr("UDP 端口"))

                if (QGroundControl.linkManager.serialPorts.length === 0) {
                    model.push(qsTr("串口（无可用设备）"))
                } else {
                    for (var i in QGroundControl.linkManager.serialPorts) {
                        model.push(QGroundControl.linkManager.serialPorts[i])
                    }
                }
                nmeaPortCombo.model = model

                const index = nmeaPortCombo.comboBox.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString)
                nmeaPortCombo.currentIndex = index
            }
        }

        LabelledComboBox {
            id: nmeaBaudCombo
            visible: (nmeaPortCombo.currentText !== qsTr("UDP 端口")) && (nmeaPortCombo.currentText !== qsTr("禁用"))
            label: qsTr("波特率")
            model: QGroundControl.linkManager.serialBaudRates

            onActivated: (index) => {
                if (index !== -1) {
                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = parseInt(comboBox.textAt(index))
                }
            }

            Component.onCompleted: {
                const index = nmeaBaudCombo.comboBox.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString)
                nmeaBaudCombo.currentIndex = index
            }
        }

        LabelledFactTextField {
            visible: nmeaPortCombo.currentText === qsTr("UDP 端口")
            label: qsTr("NMEA 数据流 UDP 端口")
            fact: QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort
        }
    }

    SettingsGroupLayout {
        heading: qsTr("通信链路")

        Repeater {
            model: _linkManager.linkConfigurations

            RowLayout {
                Layout.fillWidth:   true
                visible:            !object.dynamic

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               object.name
                }

                // 编辑
                QGCColoredImage {
                    height:                 ScreenTools.minTouchPixels
                    width:                  height
                    sourceSize.height:      height
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    smooth:                 true
                    color:                  qgcPalEdit.text
                    source:                 "/res/pencil.svg"
                    enabled:                !object.link

                    QGCPalette {
                        id: qgcPalEdit
                        colorGroupEnabled: parent.enabled
                    }

                    QGCMouseArea {
                        fillItem: parent
                        onClicked: {
                            var editingConfig = _linkManager.startConfigurationEditing(object)
                            linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
                        }
                    }
                }

                // 删除
                QGCColoredImage {
                    height:                 ScreenTools.minTouchPixels
                    width:                  height
                    sourceSize.height:      height
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    smooth:                 true
                    color:                  qgcPalDelete.text
                    source:                 "/res/TrashDelete.svg"

                    QGCPalette {
                        id: qgcPalDelete
                        colorGroupEnabled: parent.enabled
                    }

                    QGCMouseArea {
                        fillItem: parent
                        onClicked: mainWindow.showMessageDialog(
                                      qsTr("删除链路"),
                                      qsTr("确定要删除“%1”吗？").arg(object.name),
                                      Dialog.Ok | Dialog.Cancel,
                                      function () {
                                          _linkManager.removeConfiguration(object)
                                      })
                    }
                }

                // 连接/断开
                QGCButton {
                    text:       object.link ? qsTr("断开") : qsTr("连接")
                    onClicked: {
                        if (object.link) {
                            object.link.disconnect()
                        } else {
                            _linkManager.createConnectedLink(object)
                        }
                    }
                }
            }
        }

        LabelledButton {
            label:      qsTr("新增链路")
            buttonText: qsTr("新增")

            onClicked: {
                var editingConfig = _linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
                linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: null }).open()
            }
        }
    }

    Component {
        id: linkDialogComponent

        QGCPopupDialog {
            title:                  originalConfig ? qsTr("编辑链路") : qsTr("新增链路")
            buttons:                Dialog.Save | Dialog.Cancel
            acceptButtonEnabled:    nameField.text !== ""

            property var originalConfig
            property var editingConfig

            onAccepted: {
                linkSettingsLoader.item.saveSettings()
                editingConfig.name = nameField.text
                if (originalConfig) {
                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)
                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)
                }
            }

            onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            ScreenTools.defaultFontPixelWidth

                    QGCLabel { text: qsTr("名称") }
                    QGCTextField {
                        id:                 nameField
                        Layout.fillWidth:   true
                        text:               editingConfig.name
                        placeholderText:    qsTr("请输入名称")
                    }
                }

                QGCCheckBoxSlider {
                    Layout.fillWidth:   true
                    text:               qsTr("启动时自动连接")
                    checked:            editingConfig.autoConnect
                    onCheckedChanged:   editingConfig.autoConnect = checked
                }

                QGCCheckBoxSlider {
                    Layout.fillWidth:   true
                    text:               qsTr("高延迟模式")
                    checked:            editingConfig.highLatency
                    onCheckedChanged:   editingConfig.highLatency = checked
                }

                LabelledComboBox {
                    label:                  qsTr("类型")
                    enabled:                originalConfig == null
                    model:                  _linkManager.linkTypeStrings
                    Component.onCompleted:  comboBox.currentIndex = editingConfig.linkType

                    onActivated: (index) => {
                        if (index !== editingConfig.linkType) {
                            var name = nameField.text
                            editingConfig = _linkManager.createConfiguration(index, name)
                        }
                    }
                }

                Loader {
                    id:     linkSettingsLoader
                    source: subEditConfig.settingsURL

                    property var subEditConfig:         editingConfig
                    property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2
                }
            }
        }
    }
}
