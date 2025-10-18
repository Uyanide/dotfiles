import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Constants
import qs.Modules.Bar
import qs.Modules.Misc
import qs.Modules.Panel
import qs.Services

ShellRoot {
    id: root

    Loader {
        id: loader

        active: CacheService.loaded && NukeKded6.done

        sourceComponent: Item {
            Notification {
                id: notification
            }

            IPCService {
                id: ipcService
            }

            Bar {
                id: bar
            }

            Corners {
                id: corners
            }

            CalendarPanel {
                id: calendarPanel

                objectName: "calendarPanel"
            }

            ControlCenterPanel {
                id: controlCenterPanel

                objectName: "controlCenterPanel"
            }

            NotificationHistoryPanel {
                id: notificationHistoryPanel

                objectName: "notificationHistoryPanel"
            }

        }

    }

}
