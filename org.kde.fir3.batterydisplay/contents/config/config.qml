import QtQuick 2.0
import org.kde.plasma.configuration 2.0 as PlasmaConfig

PlasmaConfig.ConfigModel {
    PlasmaConfig.ConfigCategory {
        name: i18n("General")
        icon: "preferences-system-power-management"
        source: "configGeneral.qml"
    }
