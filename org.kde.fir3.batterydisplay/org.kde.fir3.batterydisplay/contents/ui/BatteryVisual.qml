/*
    Batería dibujada con el porcentaje dentro.

    El componente no decide los colores: recibe `tintColor` desde el applet.
    Así el modo con colores y el monocromo se controlan en un único sitio.
*/

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real percent: 0
    property bool hasBattery: true
    property bool charging: false
    property bool chargingAnimation: true
    property bool vertical: false
    property color tintColor: Kirigami.Theme.textColor

    readonly property real clampedPercent: Math.max(0, Math.min(100, root.percent))

    // Pulso suave del contorno mientras carga.
    property real chargePulse

    SequentialAnimation on chargePulse {
        running: root.charging && root.chargingAnimation && root.hasBattery
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 950; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 950; easing.type: Easing.InOutSine }
    }

    readonly property color outlineColor: {
        if (!root.hasBattery) {
            return Qt.alpha(root.tintColor, 0.55);
        }
        if (root.charging) {
            return Qt.alpha(root.tintColor, 0.55 + 0.45 * root.chargePulse);
        }
        return root.tintColor;
    }

    readonly property color numberColor: root.hasBattery
        ? root.tintColor
        : Kirigami.Theme.disabledTextColor

    // El terminal de la batería siempre es algo más corto que el cuerpo.
    readonly property real nubLength: Math.max(2, Math.round((root.vertical ? root.height : root.width) * 0.055))
    readonly property real nubThickness: Math.round((root.vertical ? root.width : root.height) * 0.44)

    Rectangle {
        id: nub

        x: root.vertical ? (root.width - width) / 2 : root.width - width
        y: root.vertical ? 0 : (root.height - height) / 2
        width: root.vertical ? root.nubThickness : root.nubLength
        height: root.vertical ? root.nubLength : root.nubThickness
        radius: Math.min(1.5, root.nubLength / 2)
        color: root.outlineColor
        opacity: 0.85
    }

    Rectangle {
        id: body

        x: 0
        y: root.vertical ? root.nubLength : 0
        width: root.vertical ? root.width : root.width - root.nubLength
        height: root.vertical ? root.height - root.nubLength : root.height
        color: "transparent"

        readonly property real thickness: root.vertical ? body.width : body.height
        readonly property real lineWidth: Math.max(1.5, body.thickness * 0.065)
        readonly property real innerInset: body.lineWidth + Math.max(1.5, body.thickness * 0.025)
        readonly property real usableWidth: Math.max(0, body.width - body.innerInset * 2)
        readonly property real usableHeight: Math.max(0, body.height - body.innerInset * 2)

        radius: Math.min(8, body.thickness * 0.22)
        border.width: body.lineWidth
        border.color: root.outlineColor
    }

    Rectangle {
        id: fill

        visible: root.hasBattery && root.clampedPercent > 0
        x: body.x + body.innerInset
        y: root.vertical ? body.y + body.height - body.innerInset - height : body.y + body.innerInset
        width: root.vertical ? body.usableWidth : body.usableWidth * root.clampedPercent / 100
        height: root.vertical ? body.usableHeight * root.clampedPercent / 100 : body.usableHeight
        radius: Math.max(1, body.radius - body.lineWidth - 1)
        color: Qt.alpha(root.tintColor, 0.30)
        clip: true

        Behavior on width {
            enabled: !root.vertical
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            enabled: root.vertical
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        // Barrido de "carga": una franja clara que recorre el relleno. Sólo
        // existe mientras la batería carga y la animación está activada.
        // El color es blanco translúcido para que se lea igual con temas
        // claros y oscuros.
        Rectangle {
            id: shine

            visible: root.hasBattery && root.charging && root.chargingAnimation && !root.vertical
            width: Math.max(4, Math.round(fill.width * 0.18))
            height: fill.height
            color: Qt.rgba(1, 1, 1, 0.38)

            property real sweep

            x: shine.sweep

            SequentialAnimation on sweep {
                running: shine.visible
                loops: Animation.Infinite
                NumberAnimation {
                    from: -shine.width
                    to: fill.width
                    duration: 1100
                    easing.type: Easing.InOutQuad
                }
                PauseAnimation { duration: 220 }
            }
        }

        Rectangle {
            id: shineVertical

            visible: root.hasBattery && root.charging && root.chargingAnimation && root.vertical
            width: fill.width
            height: Math.max(4, Math.round(fill.height * 0.18))
            color: Qt.rgba(1, 1, 1, 0.38)

            property real sweep

            y: shineVertical.sweep

            SequentialAnimation on sweep {
                running: shineVertical.visible
                loops: Animation.Infinite
                NumberAnimation {
                    from: -shineVertical.height
                    to: fill.height
                    duration: 1100
                    easing.type: Easing.InOutQuad
                }
                PauseAnimation { duration: 220 }
            }
        }
    }

    Text {
        id: number

        anchors.centerIn: body
        width: Math.max(0, body.width - body.innerInset * 2)
        height: Math.max(0, body.height * 0.84)
        text: root.hasBattery ? Math.round(root.clampedPercent) : "—"
        color: root.numberColor
        font.bold: true
        font.pixelSize: Math.max(7, Math.round(body.thickness * 0.63))
        fontSizeMode: Text.Fit
        minimumPixelSize: 6
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
    }
}
