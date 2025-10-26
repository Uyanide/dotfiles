import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    property var date: new Date()
    property string time: Qt.formatDateTime(date, "HH:mm")
    property string dateString: {
        let now = date;
        let dayName = now.toLocaleDateString(Qt.locale(), "ddd");
        dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1);
        let day = now.getDate();
        let suffix;
        if (day > 3 && day < 21)
            suffix = 'th';
        else
            switch (day % 10) {
        case 1:
            suffix = "st";
            break;
        case 2:
            suffix = "nd";
            break;
        case 3:
            suffix = "rd";
            break;
        default:
            suffix = "th";
        };
        let month = now.toLocaleDateString(Qt.locale(), "MMMM");
        let year = now.toLocaleDateString(Qt.locale(), "yyyy");
        return `${dayName}, ` + `${day}${suffix} ${month} ${year}`;
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.date = new Date()
    }

}
