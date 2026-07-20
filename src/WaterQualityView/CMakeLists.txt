qt_add_library(WaterQualityViewModule STATIC)

target_include_directories(WaterQualityViewModule
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../QmlControls
)

target_link_libraries(WaterQualityViewModule
    PRIVATE
        Qt6::Core
        Qt6::Qml
        Qt6::Positioning
        Qt6::WebSockets
)

qt_add_qml_module(WaterQualityViewModule
    URI QGroundControl.WaterQualityView
    VERSION 1.0
    RESOURCE_PREFIX /qml
    SOURCES
        WaterQualityManager.h
        WaterQualityManager.cc
    QML_FILES
        WaterQualityView.qml
    NO_PLUGIN
)