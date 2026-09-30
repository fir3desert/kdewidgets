import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.ipdisplay 1.0

// A single "label : value" line in the popup.
// Clicking a row that has a value copies it to the clipboard and flashes a
// check mark, so addresses and counters can be pasted elsewhere without
// selecting text. The value is drawn in a monospace font so IPv4, IPv6 and
// byte counts line up between rows.
Item {
    id: infoRow
    Layout.fillWidth: true
    Layout.preferredHeight: 32

    property string label
    property string value
    property string icon: ""
    property color valueColor: Kirigami.Theme.textColor
    // Passed in by the caller; used only to reach copyToClipboard().
    property var networkInfo

    // Highlight shown while hovering a row that has a value.
    Rectangle {
        id: hoverBg
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        color: Kirigami.Theme.highlightColor
        opacity: 0
        radius: 4
        z: 0

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    // Icon, label, value. The label keeps a fixed width so every value in the
    // popup starts at the same horizontal position.
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing
        z: 1

        Kirigami.Icon {
            source: infoRow.icon
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            visible: infoRow.icon !== ""
            opacity: 0.6
        }

        Label {
            text: infoRow.label
            opacity: 0.6
            Layout.preferredWidth: 90
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Label {
            text: infoRow.value || "—"
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.family: "monospace"
            color: infoRow.value ? infoRow.valueColor : Kirigami.Theme.disabledTextColor
            opacity: infoRow.value ? 1.0 : 0.4
        }
    }

    // Copy to clipboard on click, and show the value in the tooltip.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: infoRow.value ? Qt.PointingHandCursor : Qt.ArrowCursor
        z: 2

        onEntered: {
            if (infoRow.value) {
                hoverBg.opacity = 0.12
            }
        }

        onExited: {
            hoverBg.opacity = 0
        }

        onClicked: {
            if (infoRow.value && infoRow.networkInfo) {
                infoRow.networkInfo.copyToClipboard(infoRow.value)
                copiedFeedback.start()
            }
        }

        ToolTip {
            visible: parent.containsMouse && infoRow.value !== ""
            text: i18n("Click to copy: %1", infoRow.value)
        }

        Timer {
            id: copiedFeedback
            interval: 1200
            onTriggered: hoverBg.opacity = 0
        }
    }

    // The "copied" check mark, shown while the feedback timer runs.
    Label {
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.verticalCenter: parent.verticalCenter
        text: "✓"
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        color: "#27ae60"
        opacity: copiedFeedback.running ? 1 : 0
        z: 3
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
