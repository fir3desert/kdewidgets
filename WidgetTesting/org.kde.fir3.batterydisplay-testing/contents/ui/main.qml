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

    readonly property bool demo: Plasmoid.configuration.demoMode === true
    readonly property bool demoCharging: Plasmoid.configuration.demoCharging === true

    // The colors (orange/red/green) can be disabled in Settings.
    readonly property bool colorize: Plasmoid.configuration.colorize !== false

    function settingNumber(value, fallback) {
        const parsed = Number(value);
        return isNaN(parsed) ? fallback : Math.round(parsed);
    }

    readonly property int warningLevel: Math.max(1, root.settingNumber(Plasmoid.configuration.warningLevel, 20))
    readonly property int criticalLevel: Math.min(root.warningLevel,
        Math.max(1, root.settingNumber(Plasmoid.configuration.criticalLevel, 10)))
    readonly property int demoPercent: Math.max(0, Math.min(100,
        root.settingNumber(Plasmoid.configuration.demoPercent, 79)))

    readonly property bool hasBattery: root.demo || batteryModel.hasBatteries

    readonly property int percent: {
        if (!root.hasBattery) {
            return 0;
        }
        const value = root.demo ? root.demoPercent : batteryModel.percent;
        return Math.max(0, Math.min(100, Math.round(value)));
    }

    readonly property int chargeState: {
        if (!root.hasBattery) {
            return BatteryControlModel.NoCharge;
        }
        if (root.demo) {
            if (root.demoPercent >= 100) {
                return BatteryControlModel.FullyCharged;
            }
            return root.demoCharging ? BatteryControlModel.Charging : BatteryControlModel.Discharging;
        }
        return batteryModel.state;
    }

    readonly property bool charging: root.chargeState === BatteryControlModel.Charging
    readonly property bool fullyCharged: root.chargeState === BatteryControlModel.FullyCharged
    readonly property bool pluggedIn: root.demo ? root.demoCharging : batteryModel.pluggedIn

    readonly property real remainingMsec: {
        if (!root.hasBattery || root.fullyCharged) {
            return 0;
        }
        if (root.demo) {
            // Plausible values so the preview also shows a time:
            // ~6 h to discharge and ~1.5 h to charge fully.
            return root.charging
                ? (100 - root.percent) * 54000
                : root.percent * 216000;
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
        // still shown while the battery is charging (or in the preview).
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
        if (state === BatteryControlModel.Charging || state === BatteryControlModel.FullyCharged) {
            return Kirigami.Theme.positiveTextColor;
        }
        return Kirigami.Theme.textColor;
    }

    function deviceStateText(state) {
        switch (state) {
        case BatteryControlModel.Charging:
            return "Charging";
        case BatteryControlModel.Discharging:
            return "Discharging";
        case BatteryControlModel.FullyCharged:
            return "Fully charged";
        case BatteryControlModel.NoCharge:
            return "Not charging";
        default:
            return "Unknown";
        }
    }

    readonly property string stateText: {
        if (!root.hasBattery) {
            return "No battery";
        }
        switch (root.chargeState) {
        case BatteryControlModel.Charging:
            return "Charging";
        case BatteryControlModel.Discharging:
            return root.pluggedIn ? "Plugged in, discharging" : "Discharging";
        case BatteryControlModel.FullyCharged:
            return "Fully charged";
        case BatteryControlModel.NoCharge:
            return root.pluggedIn ? "Idle" : "Not charging";
        default:
            return "Unknown";
        }
    }

    function formatDuration(msec) {
        const totalMinutes = Math.max(0, Math.round(msec / 60000));
        if (totalMinutes < 1) {
            return "less than 1 min";
        }
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        if (hours > 0) {
            return hours + " h " + (minutes < 10 ? "0" + minutes : minutes) + " min";
        }
        return minutes + " min";
    }

    readonly property string remainingText: {
        if (!root.hasBattery || root.fullyCharged || root.remainingMsec <= 0) {
            return "";
        }
        if (root.charging) {
            return root.formatDuration(root.remainingMsec) + " until full";
        }
        if (root.chargeState === BatteryControlModel.Discharging) {
            return root.formatDuration(root.remainingMsec) + " remaining";
        }
        return "";
    }

    function openConfiguration() {
        const action = Plasmoid.internalAction("configure");
        if (action) {
            action.trigger();
        }
    }

    // ---------------------------------------------------------------------
    // Applet
    // ---------------------------------------------------------------------

    Plasmoid.title: "Battery"
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

    toolTipMainText: root.hasBattery ? "Battery at " + root.percent + " %" : "Battery"
    toolTipSubText: {
        const parts = [];
        if (!root.hasBattery) {
            parts.push("No battery detected");
        } else {
            parts.push(root.stateText);
            if (root.remainingText !== "") {
                parts.push(root.remainingText);
            }
        }
        if (root.demo) {
            parts.push("Simulated preview data");
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
        Accessible.name: "Battery: " + (root.hasBattery ? root.percent + " %" : "no battery")
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
            percent: root.percent
            hasBattery: root.hasBattery
            charging: root.charging
            chargingAnimation: Plasmoid.configuration.chargingAnimation !== false
            animationStyle: Plasmoid.configuration.chargingAnimationStyle || "sweep"
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
                text: "Battery"
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.demo
                implicitWidth: demoLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                implicitHeight: demoLabel.implicitHeight + Kirigami.Units.smallSpacing
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.neutralTextColor, 0.55)

                PlasmaComponents3.Label {
                    id: demoLabel
                    anchors.centerIn: parent
                    text: "Preview"
                    color: Kirigami.Theme.neutralTextColor
                    font: Kirigami.Theme.smallFont
                }
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
                percent: root.percent
                hasBattery: root.hasBattery
                charging: root.charging
                chargingAnimation: Plasmoid.configuration.chargingAnimation !== false
                animationStyle: Plasmoid.configuration.chargingAnimationStyle || "sweep"
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
                text: root.demo ? "Simulated battery" : "Devices"
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                Layout.fillWidth: true
            }

            // Simulated preview row.
            ColumnLayout {
                visible: root.demo
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        text: "Preview battery"
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    PlasmaComponents3.Label {
                        text: root.percent + " %"
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

                    Rectangle {
                        width: parent.width * root.percent / 100
                        height: parent.height
                        radius: parent.radius
                        color: root.colorForDevice(root.percent, root.chargeState)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        text: root.stateText
                        font: Kirigami.Theme.smallFont
                        opacity: 0.7
                        Layout.fillWidth: true
                    }

                    PlasmaComponents3.Label {
                        text: "Simulated data"
                        font: Kirigami.Theme.smallFont
                        opacity: 0.55
                    }
                }
            }

            Repeater {
                model: root.demo ? [] : batteryModel

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
                            text: PrettyName && PrettyName.length > 0 ? PrettyName : "Battery"
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
                            text: "Health: " + deviceRow.deviceHealth + " %"
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
                    text: "No battery detected on this device."
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: "If you just want to check the layout, you can enable the preview in Settings."
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
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
                text: "Settings"
                icon.name: "configure"
                onClicked: {
                    root.expanded = false;
                    root.openConfiguration();
                }
            }
        }
    }
}
