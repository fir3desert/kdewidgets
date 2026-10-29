/*
    Modelo de configuración del applet.

    Sin este archivo Plasma no muestra ninguna página de ajustes propia del
    widget. Cada ConfigCategory es una pestaña del diálogo y su `source` es
    un QML dentro de contents/ui.
*/

import QtQuick 2.0

import org.kde.plasma.configuration 2.0 as PlasmaConfig

PlasmaConfig.ConfigModel {
    PlasmaConfig.ConfigCategory {
        name: i18n("General")
        icon: "preferences-system-power-management"
        source: "configGeneral.qml"
    }
}
