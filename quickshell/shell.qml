import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Constants
import qs.Modules.Bar
import qs.Modules.Misc
import qs.Modules.Panel
import qs.Services

Scope {
    id: root

    IPCService {
        id: ipcService
    }

    Bar {
        id: bar

        shell: root
    }

    Corners {
        id: corners

        shell: root
    }

    CalendarPanel {
        id: calendarPanel

        objectName: "calendarPanel"
    }

    ControlCenterPanel {
        id: controlCenterPanel

        objectName: "controlCenterPanel"
    }

}
