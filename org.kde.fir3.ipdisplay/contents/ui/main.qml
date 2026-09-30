import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.ipdisplay 1.0
import "../code/Network.js" as Network

PlasmoidItem {
    id: root

    property var networkInfo: NetworkInfo {}
    property int compactStatus: networkInfo.status

    // Read from the applet configuration (see ConfigGeneral.qml), so the
    // config dialog actually takes effect.
    property bool showIpv6: Plasmoid.configuration.showIpv6
    property bool showPublicIp: Plasmoid.configuration.showPublicIp
    property int updateInterval: Plasmoid.configuration.updateInterval

    // =====================================================================
    // VPN detection
    // ---------------------------------------------------------------------
    // The interface name is useless on its own for detecting a VPN: it can be
    // "wg0" or "tun0", but also "home", "office" or "work-vpn" — any name you
    // choose. So the primary signal is networkInfo.vpnActive, which the plugin
    // gets from NetworkManager, which knows whether the active connection is a
    // VPN/wireguard type.
    //
    // The old code required both conditions at once (vpnActive AND a
    // tunnel-looking name), so with an arbitrarily named VPN the condition
    // stayed false and the panel dot never turned purple.
    //
    // Now: if the plugin says there is a VPN, its name is accepted whatever it
    // is; the interface name is also checked as a second route to catch VPNs
    // that NetworkManager does not report.
    // =====================================================================
    function isVpnInterface(n) {
        if (!n || n.length === 0) return false;
        return /^(wg|tun|tap|ppp|utun|zt|ipsec|nordlynx|nordvpn|tailscale|cscotun|wgquick)[0-9]*|vpn|tunnel|zerotier|mullvad|proton|torguard|expressvpn|surfshark/i.test(n);
    }

    // The tunnel interface that is really there:
    //  1) the one the plugin reports when it says there is a VPN (it may be
    //     called "home", not just "wg0"),
    //  2) otherwise the main interface when its name looks like a tunnel.
    readonly property string vpnIface: {
        if (networkInfo.vpnActive && networkInfo.vpnIfaceName !== "")
            return networkInfo.vpnIfaceName;
        if (isVpnInterface(networkInfo.interfaceName))
            return networkInfo.interfaceName;
        if (networkInfo.vpnIfaceName !== "" && networkInfo.vpnIp !== "")
            return networkInfo.vpnIfaceName;
        return "";
    }

    readonly property bool vpnActive: vpnIface !== ""

    // VPN address: the one the plugin gives, and if there is none but the
    // tunnel is the main interface, that interface's own local address.
    readonly property string vpnIp: networkInfo.vpnIp
                                 || (networkInfo.interfaceName === vpnIface ? networkInfo.localIpv4 : "")

    // The popup's VPN row: "10.0.32.7 (wg0)", drawn in blue (valueColor). The
    // interface name is only shown here, never in the panel.
    function vpnText() {
        if (!root.vpnActive) return i18n("Inactive");
        if (root.vpnIp && root.vpnIface) return root.vpnIp + " (" + root.vpnIface + ")";
        if (root.vpnIp) return root.vpnIp;
        if (root.vpnIface) return "(" + root.vpnIface + ")";
        return i18n("VPN");
    }

    // Public address: IPv4, and IPv6 when there is no IPv4.
    readonly property string publicIp: networkInfo.publicIpv4 || networkInfo.publicIpv6

    // LAN address shown in the panel. The plugin reports the active
    // interface's address in localIpv4, and with a VPN up that is usually
    // still the physical interface (a tunnel typically carries a /32 and
    // does not become the default route), so this is the LAN address. The
    // guard is there for the case where the tunnel *is* the default route:
    // then localIpv4 is the VPN address and showing it twice would be odd,
    // so it is left to the VPN row in the popup.
    readonly property string lanIp: {
        var l = networkInfo.localIpv4 || "";
        if (root.vpnActive && root.vpnIp !== "" && l === root.vpnIp)
            return "";
        return l;
    }

    // Panel: the LAN address only, never the VPN one, and no interface name.
    // The purple dot already signals that the VPN is up, and the popup shows
    // the VPN address in its own row.
    property string compactIp: root.lanIp || (root.vpnActive ? root.vpnIp : "") || "—"

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: 320
        Layout.minimumHeight: 340
        Layout.preferredWidth: 340
        Layout.preferredHeight: 420
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18n("Network Information")
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: {
                        if (root.vpnActive) return "#b300ff";
                        if (compactStatus === 0) return "#0ffc72";
                        if (compactStatus === 1) return "#ff7700";
                        return "#ff0019";
                    }
                }

                Label {
                    text: {
                        if (root.vpnActive) return i18n("VPN");
                        if (compactStatus === 0) return i18n("Online");
                        if (compactStatus === 1) return i18n("No Internet");
                        return i18n("Offline");
                    }
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            height: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: infoColumn.height

            ColumnLayout {
                id: infoColumn
                width: parent.width
                spacing: 0

                InfoRow {
                    label: i18n("LAN")
                    value: networkInfo.localIpv4
                    icon: "network-wired"
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("Public")
                    // IPv4 when there is one, otherwise IPv6.
                    value: root.publicIp
                    icon: "internet-services"
                    visible: showPublicIp
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("IPv6")
                    value: networkInfo.localIpv6
                    icon: "network-wired"
                    visible: showIpv6 && networkInfo.localIpv6 !== ""
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("Interface")
                    value: networkInfo.interfaceName
                    icon: "interface"
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("Gateway")
                    value: networkInfo.gateway
                    icon: "network-wired"
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("DNS")
                    value: networkInfo.dnsList && networkInfo.dnsList.length > 0 ? networkInfo.dnsList[0] : ""
                    icon: "network-wired"
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("VPN")
                    // "10.0.32.7 (wg0)" -> VPN address and interface.
                    value: root.vpnText()
                    icon: "network-vpn"
                    valueColor: root.vpnActive ? "#2980b9" : Kirigami.Theme.textColor
                    networkInfo: root.networkInfo
                }

                Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    height: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                }

                Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }

                InfoRow {
                    label: i18n("RX")
                    value: Network.formatBytes(networkInfo.rxBytes)
                    icon: "arrow-down"
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("TX")
                    value: Network.formatBytes(networkInfo.txBytes)
                    icon: "arrow-up"
                    networkInfo: root.networkInfo
                }

                InfoRow {
                    label: i18n("Last update")
                    value: networkInfo.lastUpdate
                    icon: "view-refresh"
                    networkInfo: root.networkInfo
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            height: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Button {
                text: i18n("Refresh")
                icon.name: "view-refresh"
                Layout.fillWidth: true
                onClicked: networkInfo.refresh()
            }
        }
    }

    compactRepresentation: Item {
        id: compactRoot

        property real dotSize: 8
        property real spacing_: Kirigami.Units.smallSpacing
        property real margins: Kirigami.Units.largeSpacing

        implicitWidth: dotSize + spacing_ + textItem.paintedWidth + margins * 2
        implicitHeight: textItem.implicitHeight + margins

        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight

        Row {
            id: compactRow
            anchors.centerIn: parent
            spacing: compactRoot.spacing_

            Rectangle {
                width: compactRoot.dotSize
                height: compactRoot.dotSize
                radius: compactRoot.dotSize / 2
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    if (root.vpnActive) return "#b300ff";
                    if (compactStatus === 0) return "#0ffc72";
                    if (compactStatus === 1) return "#ff7700";
                    return "#ff0019";
                }
            }

            Text {
                id: textItem
                text: compactIp
                color: Kirigami.Theme.textColor
                font: Kirigami.Theme.defaultFont
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideNone
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    // =====================================================================
    // Polling
    // ---------------------------------------------------------------------
    // Data used to be requested only when the popup was opened, so the panel
    // dot kept its old colour until you clicked. This timer keeps asking the
    // plugin, so the dot turns purple as soon as a VPN comes up, without
    // touching anything.
    //
    // The interval comes from the applet configuration (in seconds), so the
    // "Update interval" setting in the config dialog is honoured. It is only
    // polled while the popup is closed, because the popup refreshes on open
    // anyway and 30 seconds without data would look stale.
    // =====================================================================
    Timer {
        id: pollTimer
        interval: Math.max(1, root.updateInterval) * 1000
        repeat: true
        running: !root.expanded
        onTriggered: networkInfo.refresh()
    }

    // Re-arm the timer when the config dialog changes the interval.
    onUpdateIntervalChanged: pollTimer.restart()

    Component.onCompleted: networkInfo.refresh()

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                networkInfo.refresh()
            }
        }
    }
}
