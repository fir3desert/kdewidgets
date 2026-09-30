import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    // The interface list is filled from the current network interface, falling
    // back to whatever is stored, because the plugin does not expose an
    // interface enumeration through QML.
    function knownInterfaces() {
        var list = [];
        var current = Plasmoid.configuration.specificInterface || "";
        if (current !== "")
            list.push(current);
        return list;
    }

    function saveConfig() {
        Plasmoid.config = {
            "autoUpdate": autoUpdateCheck.checked,
            "updateInterval": intervalSpinBox.value,
            "showPublicIp": showPublicCheck.checked,
            "showIpv6": showIpv6Check.checked,
            "autoInterface": autoIfaceCheck.checked,
            "specificInterface": ifaceCombo.currentText,
            "publicIpTimeout": timeoutSpinBox.value,
            "publicIpV4Endpoints": v4EndpointsArea.text.split("\n").map(function(s) { return s.trim(); }).filter(function(s) { return s !== ""; }),
            "publicIpV6Endpoints": v6EndpointsArea.text.split("\n").map(function(s) { return s.trim(); }).filter(function(s) { return s !== ""; })
        };
    }

    spacing: Kirigami.Units.smallSpacing

    CheckBox {
        id: autoUpdateCheck
        text: i18n("Auto-update")
        checked: Plasmoid.configuration.autoUpdate
        onCheckedChanged: root.saveConfig()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Update interval (s):")
            Layout.preferredWidth: 160
        }

        SpinBox {
            id: intervalSpinBox
            from: 1
            to: 30
            // This is how often the panel polls the plugin while the popup is
            // closed, so 1s is responsive and 30s is gentle on the network.
            value: Plasmoid.configuration.updateInterval
            onValueChanged: root.saveConfig()
        }
    }

    CheckBox {
        id: showPublicCheck
        text: i18n("Show public IP")
        checked: Plasmoid.configuration.showPublicIp
        onCheckedChanged: root.saveConfig()
    }

    CheckBox {
        id: showIpv6Check
        text: i18n("Show IPv6")
        checked: Plasmoid.configuration.showIpv6
        onCheckedChanged: root.saveConfig()
    }

    CheckBox {
        id: autoIfaceCheck
        text: i18n("Auto-detect interface")
        checked: Plasmoid.configuration.autoInterface
        onCheckedChanged: root.saveConfig()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Interface:")
            Layout.preferredWidth: 160
        }

        ComboBox {
            id: ifaceCombo
            enabled: !autoIfaceCheck.checked
            // Editable, because the plugin cannot enumerate interfaces; the
            // user types the name (e.g. wg0, eth0) by hand.
            editable: true
            model: root.knownInterfaces()
            currentText: Plasmoid.configuration.specificInterface || ""
            onAccepted: root.saveConfig()
            onEditingFinished: root.saveConfig()
            Layout.fillWidth: true
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Label {
            text: i18n("Public IP timeout (ms):")
            Layout.preferredWidth: 160
        }

        SpinBox {
            id: timeoutSpinBox
            from: 1000
            to: 15000
            stepSize: 1000
            value: Plasmoid.configuration.publicIpTimeout
            onValueChanged: root.saveConfig()
        }
    }

    Label {
        text: i18n("Public IPv4 endpoints (one per line):")
        font.bold: true
    }

    TextArea {
        id: v4EndpointsArea
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        text: (Plasmoid.configuration.publicIpV4Endpoints || ["https://api.ipify.org", "https://ifconfig.me"]).join("\n")
        wrapMode: TextEdit.Wrap
        onTextEditingFinished: root.saveConfig()
    }

    Label {
        text: i18n("Public IPv6 endpoints (one per line):")
        font.bold: true
    }

    TextArea {
        id: v6EndpointsArea
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        text: (Plasmoid.configuration.publicIpV6Endpoints || ["https://api6.ipify.org", "https://ifconfig.me"]).join("\n")
        wrapMode: TextEdit.Wrap
        onTextEditingFinished: root.saveConfig()
    }
}
