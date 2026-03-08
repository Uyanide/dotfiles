import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Modules.Background
import qs.Modules.Bar
import qs.Modules.Misc
import qs.Modules.Sidebar
import qs.Services

ShellRoot {
    id: root

    Component.onCompleted: {
        ImageCacheService.init();
    }

    Loader {
        id: loader

        active: Init.initialized

        sourceComponent: Item {
            Component.onCompleted: {
                SunsetService;
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

            Sidebars {
                id: sidebars
            }

            Notification {
                id: notification
            }

            Background {
                id: background
            }

        }

    }

}
