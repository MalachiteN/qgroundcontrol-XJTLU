#include "QGCPalette.h"
#include "QGCCorePlugin.h"

#include <QtCore/QDebug>

QList<QGCPalette*>   QGCPalette::_paletteObjects;

QGCPalette::Theme QGCPalette::_theme = QGCPalette::Dark;

QMap<int, QMap<int, QMap<QString, QColor>>> QGCPalette::_colorInfoMap;

QStringList QGCPalette::_colors;

QGCPalette::QGCPalette(QObject* parent) :
    QObject(parent),
    _colorGroupEnabled(true)
{
    if (_colorInfoMap.isEmpty()) {
        _buildMap();
    }

    // We have to keep track of all QGCPalette objects in the system so we can signal theme change to all of them
    _paletteObjects += this;
}

QGCPalette::~QGCPalette()
{
    bool fSuccess = _paletteObjects.removeOne(this);
    if (!fSuccess) {
        qWarning() << "Internal error";
    }
}

void QGCPalette::_buildMap()
{
    //                                      Light                 Dark
    //                                      Disabled   Enabled    Disabled   Enabled
    // --- Window/Surface system: blue-charcoal foundation ---
    DECLARE_QGC_COLOR(window,               "#f0f4f8", "#f0f4f8", "#121820", "#121820")
    DECLARE_QGC_COLOR(windowTransparent,    "#ccf0f4f8", "#ccf0f4f8", "#cc121820", "#cc121820")
    DECLARE_QGC_COLOR(windowShadeLight,     "#c8d4e0", "#c0ccd8", "#384050", "#283040")
    DECLARE_QGC_COLOR(windowShade,          "#dfe8f0", "#dfe8f0", "#1c242c", "#1c242c")
    DECLARE_QGC_COLOR(windowShadeDark,      "#b0bcc8", "#b0bcc8", "#0e1419", "#0e1419")
    DECLARE_QGC_COLOR(text,                 "#8090a0", "#1a2530", "#506070", "#e0e6ed")
    DECLARE_QGC_COLOR(windowTransparentText,"#8090a0", "#1a2530", "#506070", "#e0e6ed")
    DECLARE_QGC_COLOR(warningText,          "#cc0808", "#cc0808", "#ff6b6b", "#ff6b6b")
    // --- Button system: teal accent ---
    DECLARE_QGC_COLOR(button,               "#e0e8f0", "#ffffff", "#283040", "#2a3340")
    DECLARE_QGC_COLOR(buttonBorder,         "#8090a0", "#00798c", "#3a4a5c", "#3a4a5c")
    DECLARE_QGC_COLOR(buttonText,           "#8090a0", "#1a2530", "#7080a0", "#d0d8e0")
    DECLARE_QGC_COLOR(buttonHighlight,      "#b0d0d8", "#00798c", "#0a2830", "#006a7a")
    DECLARE_QGC_COLOR(buttonHighlightText,  "#1a2530", "#ffffff", "#e0e6ed", "#ffffff")
    DECLARE_QGC_COLOR(primaryButton,        "#5a8090", "#00798c", "#1a3838", "#00798c")
    DECLARE_QGC_COLOR(primaryButtonText,    "#d0e0e0", "#ffffff", "#d0e0e0", "#e0f5f5")
    DECLARE_QGC_COLOR(textField,            "#e8eef4", "#ffffff", "#1c242c", "#1c242c")
    DECLARE_QGC_COLOR(textFieldText,        "#8090a0", "#1a2530", "#7080a0", "#d0d8e0")
    // --- Map system: dark base + teal accents ---
    DECLARE_QGC_COLOR(mapButton,            "#4a5a6a", "#1a2530", "#4a5a6a", "#0a1015")
    DECLARE_QGC_COLOR(mapButtonHighlight,   "#4a5a6a", "#00798c", "#4a5a6a", "#00a8a8")
    DECLARE_QGC_COLOR(mapIndicator,         "#4a5a6a", "#00798c", "#4a5a6a", "#00a8a8")
    DECLARE_QGC_COLOR(mapIndicatorChild,    "#4a5a6a", "#005060", "#4a5a6a", "#00798c")
    // --- Status colors: maintained semantic meaning, adjusted for modern dark theme ---
    DECLARE_QGC_COLOR(colorGreen,           "#008f2d", "#008f2d", "#2ecc71", "#2ecc71")
    DECLARE_QGC_COLOR(colorYellow,          "#c0a020", "#c0a020", "#f1c40f", "#f1c40f")
    DECLARE_QGC_COLOR(colorYellowGreen,     "#799f26", "#799f26", "#a8d672", "#a8d672")
    DECLARE_QGC_COLOR(colorOrange,          "#bf6515", "#bf6515", "#e67e22", "#e67e22")
    DECLARE_QGC_COLOR(colorRed,             "#cc0808", "#cc0808", "#e74c3c", "#e74c3c")
    DECLARE_QGC_COLOR(colorGrey,            "#808080", "#808080", "#95a5a6", "#95a5a6")
    DECLARE_QGC_COLOR(colorBlue,            "#1a72ff", "#1a72ff", "#3498db", "#3498db")
    // --- Alert system: warm amber for caution, not red for error ---
    DECLARE_QGC_COLOR(alertBackground,      "#f39c12", "#f39c12", "#f39c12", "#f39c12")
    DECLARE_QGC_COLOR(alertBorder,          "#8090a0", "#8090a0", "#3a4a5c", "#3a4a5c")
    DECLARE_QGC_COLOR(alertText,            "#1a2530", "#1a2530", "#1a2530", "#1a2530")
    // --- Mission / Editor / Toolbar ---
    DECLARE_QGC_COLOR(missionItemEditor,    "#4a5a6a", "#dfe8f0", "#4a5a6a", "#1c242c")
    DECLARE_QGC_COLOR(toolStripHoverColor,  "#4a5a6a", "#00798c", "#4a5a6a", "#0a3838")
    DECLARE_QGC_COLOR(statusFailedText,     "#8090a0", "#1a2530", "#506070", "#e0e6ed")
    DECLARE_QGC_COLOR(statusPassedText,     "#8090a0", "#1a2530", "#506070", "#e0e6ed")
    DECLARE_QGC_COLOR(statusPendingText,    "#8090a0", "#1a2530", "#506070", "#e0e6ed")
    DECLARE_QGC_COLOR(toolbarBackground,    "#00f0f4f8", "#00f0f4f8", "#00121820", "#00121820")
    DECLARE_QGC_COLOR(groupBorder,          "#8090a0", "#00798c", "#3a4a5c", "#3a4a5c")

    // Branding: teal replaces purple entirely
    //                                                      Disabled     Enabled
    DECLARE_QGC_NONTHEMED_COLOR(brandingPurple,             "#00798c", "#00798c")
    DECLARE_QGC_NONTHEMED_COLOR(brandingBlue,               "#005060", "#00a8a8")
    DECLARE_QGC_NONTHEMED_COLOR(toolStripFGColor,           "#506070", "#e0e6ed")
    DECLARE_QGC_NONTHEMED_COLOR(photoCaptureButtonColor,    "#506070", "#e0e6ed")
    DECLARE_QGC_NONTHEMED_COLOR(videoCaptureButtonColor,    "#cc5050", "#e74c3c")

    // Colors not affecting by theming or enable/disable
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderLight,          "#ffffff")
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderDark,           "#000000")
    DECLARE_QGC_SINGLE_COLOR(mapMissionTrajectory,          "#00a8a8")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonInterior,         "green")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonTerrainCollision, "red")

// Colors for UTM Adapter
#ifdef QGC_UTM_ADAPTER
    DECLARE_QGC_COLOR(switchUTMSP,        "#b0e0e6", "#b0e0e6", "#b0e0e6", "#b0e0e6");
    DECLARE_QGC_COLOR(sliderUTMSP,        "#9370db", "#9370db", "#9370db", "#9370db");
    DECLARE_QGC_COLOR(successNotifyUTMSP, "#3cb371", "#3cb371", "#3cb371", "#3cb371");
#endif
}

void QGCPalette::setColorGroupEnabled(bool enabled)
{
    _colorGroupEnabled = enabled;
    emit paletteChanged();
}

void QGCPalette::setGlobalTheme(Theme newTheme)
{
    // Mobile build does not have themes
    if (_theme != newTheme) {
        _theme = newTheme;
        _signalPaletteChangeToAll();
    }
}

void QGCPalette::_signalPaletteChangeToAll()
{
    // Notify all objects of the new theme
    for (QGCPalette *palette : std::as_const(_paletteObjects)) {
        palette->_signalPaletteChanged();
    }
}

void QGCPalette::_signalPaletteChanged()
{
    emit paletteChanged();
}
