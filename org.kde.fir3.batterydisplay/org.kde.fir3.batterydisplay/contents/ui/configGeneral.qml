import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

/*
    Página de ajustes del applet.

    Se usan alias cfg_* en lugar de escribir directamente en
    Plasmoid.configuration: así el diálogo respeta Aplicar y Cancelar.
*/
KCM.SimpleKCM {
    id: page

    property alias cfg_colorize: colorizeCheck.checked
    property alias cfg_warningLevel: warningSpin.value
    property alias cfg_criticalLevel: criticalSpin.value
    property alias cfg_chargingAnimation: chargingCheck.checked
    property alias cfg_demoMode: demoCheck.checked
    property alias cfg_demoPercent: demoSpin.value
    property alias cfg_demoCharging: demoChargingCheck.checked

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: colorizeCheck

            Kirigami.FormData.label: "Colores:"
            text: "Cambiar de color según el nivel y la carga"
        }

        QQC2.SpinBox {
            id: warningSpin

            Kirigami.FormData.label: "Naranja por debajo de:"
            enabled: colorizeCheck.checked
            from: 5
            to: 60
            stepSize: 1
            editable: true
            textFromValue: function (value) { return value + " %"; }
        }

        QQC2.SpinBox {
            id: criticalSpin

            Kirigami.FormData.label: "Rojo por debajo de:"
            enabled: colorizeCheck.checked
            from: 1
            to: 30
            stepSize: 1
            editable: true
            textFromValue: function (value) { return value + " %"; }
        }

        QQC2.Label {
            text: "Con los colores activados, el estado normal usa el color de texto y sólo se colorea por debajo de esos niveles o al cargar (verde). El nivel rojo nunca supera el naranja."
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.WordWrap
        }

        QQC2.CheckBox {
            id: chargingCheck

            Kirigami.FormData.label: "Animación:"
            text: "Barrido y pulso mientras se carga"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Vista previa"
        }

        QQC2.CheckBox {
            id: demoCheck

            text: "Mostrar datos simulados"
        }

        QQC2.SpinBox {
            id: demoSpin

            Kirigami.FormData.label: "Nivel simulado:"
            enabled: demoCheck.checked
            from: 0
            to: 100
            stepSize: 1
            editable: true
            textFromValue: function (value) { return value + " %"; }
        }

        QQC2.CheckBox {
            id: demoChargingCheck

            text: "Simular que se está cargando"
            enabled: demoCheck.checked
        }

        QQC2.Label {
            text: "Útil en equipos sin batería. Desactivada, se muestran los datos reales."
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
