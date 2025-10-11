import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Constants
import qs.Modules.Bar
import qs.Modules.Misc

Scope {
    id: root

    Bar {
        id: bar

        shell: root
    }

    Corners {
        id: corners

        shell: root
    }

}
