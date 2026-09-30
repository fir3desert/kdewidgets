.pragma library

// ---------------------------------------------------------------------------
// Helpers shared by the UI. No dependencies, safe to call from bindings.
// ---------------------------------------------------------------------------

// Human-readable byte count, e.g. 1536 -> "1.5 KB".
// Guarded because the counters are unsigned but arrive as JS numbers, so a
// missing sample or an overflow must not produce "NaN undefined" in the popup.
function formatBytes(bytes) {
    var n = Number(bytes);
    if (!isFinite(n) || n <= 0)
        return "0 B";
    var units = ["B", "KB", "MB", "GB", "TB"];
    var i = Math.floor(Math.log(n) / Math.log(1024));
    if (i < 0)
        i = 0;
    if (i >= units.length)
        i = units.length - 1;
    return (n / Math.pow(1024, i)).toFixed(1) + " " + units[i];
}

// True for RFC1918 / loopback / link-local IPv4, and for IPv6 unique-local
// (fc00::/7). Used to decide whether an address is worth hiding.
function isPrivateIp(ip) {
    if (!ip)
        return false;
    if (ip.indexOf("::") !== -1 || ip.indexOf(":") !== -1) {
        return /^f[cd][0-9a-f]{2}:/i.test(ip);
    }
    if (ip.indexOf("192.168.") === 0) return true;
    if (ip.indexOf("10.") === 0) return true;
    if (ip.indexOf("172.") === 0) {
        var second = parseInt(ip.split(".")[1], 10);
        if (second >= 16 && second <= 31) return true;
    }
    if (ip.indexOf("127.") === 0) return true;
    if (ip.indexOf("169.254.") === 0) return true;
    return false;
}

// Partially hides an address for display: 192.168.1.42 -> "192.168.xxx.xxx",
// 2001:db8::1 -> "2001:db8:…". Use only where the full address is not wanted;
// the popup and the panel both show addresses in full.
function maskIp(ip) {
    if (!ip)
        return "—";
    var groups = ip.split(":");
    if (groups.length > 2) {
        return groups[0] + ":" + groups[1] + ":…";
    }
    var parts = ip.split(".");
    if (parts.length === 4) {
        return parts[0] + "." + parts[1] + ".xxx.xxx";
    }
    return ip;
}
