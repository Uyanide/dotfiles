import QtQuick
import Quickshell
pragma Singleton

Singleton {
    // ignore and fall back

    id: root

    function iconFromName(iconName, fallbackName) {
        const fallback = fallbackName || "application-x-executable";
        try {
            if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
                const p = Quickshell.iconPath(iconName, fallback);
                if (p && p !== "")
                    return p;

            }
        } catch (e) {
        }
        try {
            return Quickshell.iconPath ? (Quickshell.iconPath(fallback, true) || "") : "";
        } catch (e2) {
            return "";
        }
    }

    // Resolve icon path for a DesktopEntries appId - safe on missing entries
    function iconForAppId(appId, fallbackName) {
        const fallback = fallbackName || "application-x-executable";
        if (!appId)
            return iconFromName(fallback, fallback);

        try {
            if (typeof DesktopEntries === 'undefined' || !DesktopEntries.byId)
                return iconFromName(fallback, fallback);

            const entry = (DesktopEntries.heuristicLookup) ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId);
            const name = entry && entry.icon ? entry.icon : "";
            return iconFromName(name || fallback, fallback);
        } catch (e) {
            return iconFromName(fallback, fallback);
        }
    }

}
