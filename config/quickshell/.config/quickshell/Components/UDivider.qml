import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Constants

Rectangle {
    width: parent.width
    height: Math.max(1, Style.borderS)

    gradient: Gradient {
        orientation: Gradient.Horizontal

        GradientStop {
            position: 0
            color: Colors.transparent
        }

        GradientStop {
            position: 0.1
            color: Colors.mOutline
        }

        GradientStop {
            position: 0.9
            color: Colors.mOutline
        }

        GradientStop {
            position: 1
            color: Colors.transparent
        }

    }

}
