import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Modules.Bar.Misc
import qs.Constants
import qs.Services
import qs.Utils

Rectangle {
  id: root

  property ShellScreen screen

  implicitWidth: trayFlow.implicitWidth + 20
  implicitHeight: parent.height
  radius: 0
  color: Colors.transparent

  Layout.alignment: Qt.AlignVCenter

  Flow {
    id: trayFlow
    anchors.centerIn: parent
    spacing: 8
    flow: Flow.LeftToRight

    Repeater {
      id: repeater
      model: SystemTray.items

      delegate: Item {
        width: 18
        height: 18
        visible: modelData

        IconImage {
          id: trayIcon

          property ShellScreen screen: root.screen

          anchors.centerIn: parent
          width: 14
          height: 14
          smooth: false
          asynchronous: true
          backer.fillMode: Image.PreserveAspectFit
          source: {
            let icon = modelData?.icon || ""
            if (!icon) {
              return ""
            }

            // Process icon path
            if (icon.includes("?path=")) {
              const chunks = icon.split("?path=")
              const name = chunks[0]
              const path = chunks[1]
              const fileName = name.substring(name.lastIndexOf("/") + 1)
              return `file://${path}/${fileName}`
            }
            return icon
          }
          opacity: status === Image.Ready ? 1 : 0
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: mouse => {
                       if (!modelData) {
                         return
                       }

                       if (mouse.button === Qt.LeftButton) {
                         // Close any open menu first
                         trayPanel.close()

                         if (!modelData.onlyMenu) {
                           modelData.activate()
                         }
                       } else if (mouse.button === Qt.MiddleButton) {
                         // Close any open menu first
                         trayPanel.close()

                         modelData.secondaryActivate && modelData.secondaryActivate()
                       } else if (mouse.button === Qt.RightButton) {
                         // Close the menu if it was visible
                         if (trayPanel && trayPanel.visible) {
                           trayPanel.close()
                           return
                         }

                         if (modelData.hasMenu && modelData.menu && trayMenu.item) {
                           trayPanel.open()

                           // Position menu based on bar position
                           let menuX, menuY
                             // For horizontal bars: center horizontally and position below
                             menuX = (width / 2) - (trayMenu.item.width / 2)
                             menuY = root.height
                           trayMenu.item.menu = modelData.menu
                           trayMenu.item.showAt(parent, menuX, menuY)
                         } else {
                           Logger.log("Tray", "No menu available for", modelData.id, "or trayMenu not set")
                         }
                       }
                     }
          onEntered: {
            trayPanel.close()
          }
        }
      }
    }
  }

  PanelWindow {
    id: trayPanel
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    visible: false
    color: Colors.transparent
    screen: root.screen

    function open() {
      visible = true
      PanelService.willOpenPanel(trayPanel)
    }

    function close() {
      visible = false
      if (trayMenu.item) {
        trayMenu.item.hideMenu()
      }
    }

    // Clicking outside of the rectangle to close
    MouseArea {
      anchors.fill: parent
      onClicked: trayPanel.close()
    }

    Loader {
      id: trayMenu
    Component.onCompleted: {
        setSource("../Misc/TrayMenu.qml", {
            "screen": root.screen
        })
    }
    }
  }
}
