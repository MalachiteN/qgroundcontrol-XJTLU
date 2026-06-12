qt_add_library(AppSettingsModule STATIC)

qt_add_qml_module(AppSettingsModule
    URI QGroundControl.AppSettings
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ADSBServerSettings.qml
        BluetoothSettings.qml
        DebugWindow.qml
        DebugWindow1.qml
        FlyViewSettings.qml
        FlyViewSettings1.qml
        GeneralSettings.qml
        GeneralSettings1.qml
        HelpSettings.qml
        HelpSettings1.qml
        LinkSettings.qml
        LinkSettings1.qml
        LogReplaySettings.qml
        MapSettings.qml
        MapSettings1.qml
        NTRIPSettings.qml
        NTRIPSettings1.qml
        MockLink.qml
        MockLink1.qml
        MockLinkSettings.qml
        PlanViewSettings.qml
        PlanViewSettings1.qml
        PX4LogTransferSettings.qml
        PX4LogTransferSettings1.qml
        QmlTest.qml
        RemoteIDSettings.qml
        SerialSettings.qml
        SettingsPage.qml
        SettingsPagesModel.qml
        TcpSettings.qml
        TelemetrySettings.qml
        TelemetrySettings1.qml
        UdpSettings.qml
        VideoSettings.qml
        VideoSettings1.qml
    NO_PLUGIN
)
