/*
    Battery widget for the Plasma 6 panel.

    The panel shows a drawn battery with the percentage inside. Clicking it
    opens a summary with the state, the remaining time and the data of each
    battery. Real data comes from BatteryControlModel (UPower/PowerDevil),
    the same model used by the official KDE applet.
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.battery

PlasmoidItem {
    id: root

    // ---------------------------------------------------------------------
    // Data
    // ---------------------------------------------------------------------

    BatteryControlModel {
        id: batteryModel
    }

    // The colors (orange/red/green) can be disabled in Settings.
    readonly property bool colorize: Plasmoid.configuration.colorize !== false

    function settingNumber(value, fallback) {
        const parsed = Number(value);
        return isNaN(parsed) ? fallback : Math.round(parsed);
    }

    readonly property int warningLevel: Math.max(1, root.settingNumber(Plasmoid.configuration.warningLevel, 20))
    readonly property int criticalLevel: Math.min(root.warningLevel,
        Math.max(1, root.settingNumber(Plasmoid.configuration.criticalLevel, 10)))

    readonly property bool hasBattery: batteryModel.hasBatteries

    // Animation settings, read once here and shared by both drawings.
    readonly property bool animationEnabled: Plasmoid.configuration.chargingAnimation !== false
    readonly property string animationStyle: String(Plasmoid.configuration.chargingAnimationStyle || "sweep")
    // What the drawing receives (real data, or a fake battery in preview).
    readonly property bool visualHasBattery: root.hasBattery || root.preview

    readonly property int percent: {
        if (!root.hasBattery) {
            return 0;
        }
        const value = batteryModel.percent;
        return Math.max(0, Math.min(100, Math.round(value)));
    }

    readonly property int chargeState: {
        if (!root.hasBattery) {
            return BatteryControlModel.NoCharge;
        }
        return batteryModel.state;
    }

    // Solid::Battery::ChargeState: NoCharge=0, Charging=1, Discharging=2,
    // FullyCharged=3. The numeric fallback keeps working if the enum is not
    // exposed to QML by this Plasma version (the comparison would then be
    // against `undefined` and the animations would never start).
    function stateIs(state, named, numeric) {
        return (named !== undefined && state === named) || state === numeric;
    }

    readonly property bool realCharging: root.hasBattery
        && root.stateIs(root.chargeState, BatteryControlModel.Charging, 1)

    // Preview mode (Settings): forces the animation so it can be tried
    // without plugging the charger in, and on machines without a battery.
    readonly property bool preview: Plasmoid.configuration.previewAnimation === true
    // Connected to power but not actively charging (full battery, or a charge
    // limit reached): optionally keep the animation going.
    readonly property bool animateWhenFull: Plasmoid.configuration.animateWhenFull !== false
    readonly property bool connectedIdle: root.hasBattery && root.animateWhenFull
        && (root.fullyCharged
            || (root.pluggedIn && root.stateIs(root.chargeState, BatteryControlModel.NoCharge, 0)))

    readonly property bool charging: root.realCharging || root.connectedIdle || root.preview
    readonly property bool fullyCharged: root.hasBattery
        && root.stateIs(root.chargeState, BatteryControlModel.FullyCharged, 3)
    readonly property bool pluggedIn: batteryModel.pluggedIn

    readonly property real remainingMsec: {
        if (!root.hasBattery || root.fullyCharged) {
            return 0;
        }
        const smoothed = batteryModel.smoothedRemainingMsec;
        return smoothed > 0 ? smoothed : batteryModel.remainingMsec;
    }

    // Single accent color for the level. In the normal state it is the text
    // color (no accent); it only changes when there is a reason: orange
    // below the warning threshold, red below the critical one and green
    // while charging or fully charged. If colors are disabled, the text
    // color is always used.
    readonly property color accentColor: {
        if (!root.hasBattery) {
            return Kirigami.Theme.disabledTextColor;
        }
        if (!root.colorize) {
            return Kirigami.Theme.textColor;
        }
        // Low level takes precedence over charging green, so orange/red is
        // still shown while the battery is charging.
        if (root.percent < root.criticalLevel) {
            return Kirigami.Theme.negativeTextColor;
        }
        if (root.percent < root.warningLevel) {
            return Kirigami.Theme.neutralTextColor;
        }
        if (root.charging || root.fullyCharged) {
            return Kirigami.Theme.positiveTextColor;
        }
        return Kirigami.Theme.textColor;
    }

    readonly property color statusColor: root.accentColor

    function colorForPercent(value) {
        if (!root.colorize) {
            return Kirigami.Theme.textColor;
        }
        if (value < root.criticalLevel) {
            return Kirigami.Theme.negativeTextColor;
        }
        if (value < root.warningLevel) {
            return Kirigami.Theme.neutralTextColor;
        }
        return Kirigami.Theme.textColor;
    }

    function colorForDevice(value, state) {
        if (!root.colorize) {
            return Kirigami.Theme.textColor;
        }
        if (value < root.criticalLevel) {
            return Kirigami.Theme.negativeTextColor;
        }
        if (value < root.warningLevel) {
            return Kirigami.Theme.neutralTextColor;
        }
        if (root.stateIs(state, BatteryControlModel.Charging, 1) || root.stateIs(state, BatteryControlModel.FullyCharged, 3)) {
            return Kirigami.Theme.positiveTextColor;
        }
        return Kirigami.Theme.textColor;
    }

    function deviceStateText(state) {
        if (root.stateIs(state, BatteryControlModel.Charging, 1)) {
            return i18n("Charging");
        }
        if (root.stateIs(state, BatteryControlModel.Discharging, 2)) {
            return i18n("Discharging");
        }
        if (root.stateIs(state, BatteryControlModel.FullyCharged, 3)) {
            return i18n("Fully charged");
        }
        if (root.stateIs(state, BatteryControlModel.NoCharge, 0)) {
            return i18n("Not charging");
        }
        return i18n("Unknown");
    }

    readonly property string stateText: {
        if (!root.hasBattery) {
            return i18n("No battery");
        }
        if (root.realCharging) {
            return i18n("Charging");
        }
        if (root.stateIs(root.chargeState, BatteryControlModel.Discharging, 2)) {
            return root.pluggedIn ? i18n("Plugged in, discharging") : i18n("Discharging");
        }
        if (root.fullyCharged) {
            return i18n("Fully charged");
        }
        if (root.stateIs(root.chargeState, BatteryControlModel.NoCharge, 0)) {
            return root.pluggedIn ? i18n("Plugged in, not charging") : i18n("Not charging");
        }
        return i18n("Unknown");
    }

    function formatDuration(msec) {
        const totalMinutes = Math.max(0, Math.round(msec / 60000));
        if (totalMinutes < 1) {
            return i18n("less than 1 min");
        }
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        if (hours > 0) {
            return i18n("%1 h %2 min", hours, (minutes < 10 ? "0" + minutes : minutes));
        }
        return i18n("%1 min", minutes);
    }

    readonly property string remainingText: {
        if (!root.hasBattery || root.fullyCharged || root.remainingMsec <= 0) {
            return "";
        }
        if (root.realCharging) {
            return i18n("%1 until full", root.formatDuration(root.remainingMsec));
        }
        if (root.stateIs(root.chargeState, BatteryControlModel.Discharging, 2)) {
            return i18n("%1 remaining", root.formatDuration(root.remainingMsec));
        }
        return "";
    }

    // Diagnostics: journalctl --user -f | grep fir3.batterydisplay
    onChargeStateChanged: console.log("[fir3.batterydisplay] chargeState=" + root.chargeState
        + " percent=" + root.percent + " pluggedIn=" + root.pluggedIn
        + " charging=" + root.charging + " preview=" + root.preview)

    Component.onCompleted: console.log("[fir3.batterydisplay] 1.3.1 loaded hasBattery=" + root.hasBattery
        + " chargeState=" + root.chargeState + " percent=" + root.percent
        + " pluggedIn=" + root.pluggedIn + " preview=" + root.preview
        + " animEnabled=" + root.animationEnabled + " style=" + root.animationStyle)

    function openConfiguration() {
        const action = Plasmoid.internalAction("configure");
        if (action) {
            action.trigger();
        }
    }

    // ---------------------------------------------------------------------
    // Applet
    // ---------------------------------------------------------------------

    Plasmoid.title: i18n("Battery")
    Plasmoid.icon: !root.hasBattery
        ? "battery-missing"
        : root.percent <= 10
            ? "battery-empty"
            : root.percent <= 30
                ? "battery-low"
                : root.percent <= 70
                    ? "battery-good"
                    : "battery-full"

    Plasmoid.status: root.hasBattery && (root.charging || root.percent <= root.warningLevel)
        ? PlasmaCore.Types.ActiveStatus
        : PlasmaCore.Types.PassiveStatus

    toolTipMainText: root.hasBattery ? i18n("Battery at %1 %", root.percent) : i18n("Battery")
    toolTipSubText: {
        const parts = [];
        if (!root.hasBattery) {
            parts.push(i18n("No battery detected"));
        } else {
            parts.push(root.stateText);
            if (root.remainingText !== "") {
                parts.push(root.remainingText);
            }
        }
        return parts.join("\n");
    }

    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // ---------------------------------------------------------------------
    // Panel
    // ---------------------------------------------------------------------

    compactRepresentation: MouseArea {
        id: compact

        readonly property int thickness: Math.max(14, Kirigami.Units.iconSizes.smallMedium)
        readonly property int length: Math.round(compact.thickness * 2.35)
        readonly property int visualWidth: root.verticalPanel ? compact.thickness : compact.length
        readonly property int visualHeight: root.verticalPanel ? compact.length : compact.thickness

        implicitWidth: compact.visualWidth + 4
        implicitHeight: compact.visualHeight + 4

        Layout.minimumWidth: compact.implicitWidth
        Layout.minimumHeight: compact.implicitHeight
        Layout.preferredWidth: compact.implicitWidth
        Layout.preferredHeight: compact.implicitHeight

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: i18n("Battery: %1", root.hasBattery ? i18n("%1 %", root.percent) : i18n("no battery"))
        Accessible.description: root.stateText
            + (root.remainingText !== "" ? "; " + root.remainingText : "")

        onClicked: root.expanded = !root.expanded

        // Hover highlight. In a vertical panel the extra margin is added
        // vertically so it does not exceed the panel thickness.
        Rectangle {
            anchors.centerIn: battery
            width: battery.width + (root.verticalPanel ? 0 : 4)
            height: battery.height + (root.verticalPanel ? 4 : 0)
            radius: Math.min(width, height) * 0.28
            color: Qt.alpha(Kirigami.Theme.highlightColor, compact.containsMouse ? 0.13 : 0)
            Behavior on color {
                ColorAnimation { duration: 120 }
            }
        }

        BatteryVisual {
            id: battery

            anchors.centerIn: parent
            width: compact.visualWidth
            height: compact.visualHeight
            vertical: root.verticalPanel
            percent: root.hasBattery ? root.percent : 60
            hasBattery: root.visualHasBattery
            charging: root.charging
            chargingAnimation: root.animationEnabled
            animationStyle: root.animationStyle
            tintColor: root.accentColor
        }
    }

    // ---------------------------------------------------------------------
    // Popup
    // ---------------------------------------------------------------------

    fullRepresentation: ColumnLayout {
        id: fullRoot

        Layout.minimumWidth: Kirigami.Units.gridUnit * 17
        Layout.preferredWidth: Kirigami.Units.gridUnit * 19
        Layout.maximumWidth: Kirigami.Units.gridUnit * 25
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8
        Layout.preferredHeight: fullRoot.implicitHeight

        spacing: 0

        // Header ---------------------------------------------------------

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: i18n("Battery")
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                id: statusPill

                readonly property int dotSize: Kirigami.Units.smallSpacing + 2

                implicitWidth: statusRow.implicitWidth + Kirigami.Units.smallSpacing * 2.5
                implicitHeight: statusRow.implicitHeight + Kirigami.Units.smallSpacing
                radius: height / 2
                color: Qt.alpha(root.statusColor, 0.14)
                border.width: 1
                border.color: Qt.alpha(root.statusColor, 0.35)

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing * 0.75

                    Rectangle {
                        implicitWidth: statusPill.dotSize
                        implicitHeight: statusPill.dotSize
                        radius: width / 2
                        color: root.statusColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    PlasmaComponents3.Label {
                        text: root.stateText
                        color: root.statusColor
                        font: Kirigami.Theme.smallFont
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // Large battery --------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 7

            BatteryVisual {
                id: heroBattery

                anchors.centerIn: parent
                width: Math.min(parent.width - Kirigami.Units.gridUnit * 4,
                    Kirigami.Units.gridUnit * 11.5)
                height: Math.round(width * 0.37)
                percent: root.hasBattery ? root.percent : 60
                hasBattery: root.visualHasBattery
                charging: root.charging
                chargingAnimation: root.animationEnabled
                animationStyle: root.animationStyle
                tintColor: root.accentColor
            }
        }

        // State and remaining time ---------------------------------------

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing * 0.5

            PlasmaComponents3.Label {
                text: root.stateText
                color: root.statusColor
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            PlasmaComponents3.Label {
                text: root.remainingText
                visible: text !== ""
                font: Kirigami.Theme.smallFont
                opacity: 0.75
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            implicitHeight: 1
            color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
        }

        // Devices / no battery -------------------------------------------

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                visible: root.hasBattery
                text: i18n("Devices")
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                Layout.fillWidth: true
            }

            Repeater {
                model: batteryModel

                delegate: ColumnLayout {
                    id: deviceRow

                    readonly property int devicePercent: Math.max(0, Math.min(100, Percent))
                    readonly property int deviceHealth: Capacity
                    readonly property real deviceEnergy: Energy

                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        PlasmaComponents3.Label {
                            text: PrettyName && PrettyName.length > 0 ? PrettyName : i18n("Battery")
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        PlasmaComponents3.Label {
                            text: deviceRow.devicePercent + " %"
                            font.bold: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

                        Rectangle {
                            width: parent.width * deviceRow.devicePercent / 100
                            height: parent.height
                            radius: parent.radius
                            color: root.colorForDevice(deviceRow.devicePercent, ChargeState)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents3.Label {
                            text: root.deviceStateText(ChargeState)
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                            Layout.fillWidth: true
                        }

                        PlasmaComponents3.Label {
                            visible: deviceRow.deviceHealth > 0
                            text: i18n("Health: %1 %", deviceRow.deviceHealth)
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                        }

                        PlasmaComponents3.Label {
                            visible: deviceRow.deviceEnergy > 0
                            text: Number(deviceRow.deviceEnergy).toFixed(1) + " Wh"
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                        }
                    }
                }
            }

            // No battery
            ColumnLayout {
                visible: !root.hasBattery
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: i18n("No battery detected on this device.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }

        // Footer ---------------------------------------------------------

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            implicitHeight: 1
            color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing

            Item { Layout.fillWidth: true }

            PlasmaComponents3.Button {
                text: i18n("Settings")
                icon.name: "configure"
                onClicked: {
                    root.expanded = false;
                    root.openConfiguration();
                }
            }
        }
    }
}
