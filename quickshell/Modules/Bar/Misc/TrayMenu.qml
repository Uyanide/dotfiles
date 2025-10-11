import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Constants

PopupWindow {
  id: root
  property QsMenuHandle menu
  property var anchorItem: null
  property real anchorX
  property real anchorY
  property bool isSubMenu: false
  property bool isHovered: rootMouseArea.containsMouse
  property ShellScreen screen

  readonly property int menuWidth: 180

  implicitWidth: menuWidth

  // Use the content height of the Flickable for implicit height
  implicitHeight: Math.min(screen ? screen.height * 0.9 : Screen.height * 0.9, flickable.contentHeight + 20)
  visible: false
  color: Colors.transparent
  anchor.item: anchorItem
  anchor.rect.x: anchorX
  anchor.rect.y: anchorY - (isSubMenu ? 0 : 4)

  function showAt(item, x, y) {
    if (!item) {
      console.warn("AnchorItem is undefined, won't show menu.")
      return
    }

    if (!opener.children || opener.children.values.length === 0) {
      Qt.callLater(() => showAt(item, x, y))
      return
    }

    anchorItem = item
    anchorX = x
    anchorY = y

    visible = true
    forceActiveFocus()

    // Force update after showing.
    Qt.callLater(() => {
                   root.anchor.updateAnchor()
                 })
  }

  function hideMenu() {
    visible = false

    // Clean up all submenus recursively
    for (var i = 0; i < columnLayout.children.length; i++) {
      const child = columnLayout.children[i]
      if (child?.subMenu) {
        child.subMenu.hideMenu()
        child.subMenu.destroy()
        child.subMenu = null
      }
    }
  }

  // Full-sized, transparent MouseArea to track the mouse.
  MouseArea {
    id: rootMouseArea
    anchors.fill: parent
    hoverEnabled: true
  }

  Item {
    anchors.fill: parent
    Keys.onEscapePressed: root.hideMenu()
  }

  QsMenuOpener {
    id: opener
    menu: root.menu
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.base
    border.color: Colors.accent
    border.width: 2
    radius: 14
  }

  Flickable {
    id: flickable
    anchors.fill: parent
    anchors.margins: 10
    contentHeight: columnLayout.implicitHeight
    interactive: true

    // Use a ColumnLayout to handle menu item arrangement
    ColumnLayout {
      id: columnLayout
      width: flickable.width
      spacing: 0

      Repeater {
        model: opener.children ? [...opener.children.values] : []

        delegate: Rectangle {
          id: entry
          required property var modelData

          Layout.preferredWidth: parent.width
          Layout.preferredHeight: {
            if (modelData?.isSeparator) {
              return 8
            } else {
              // Calculate based on text content
              const textHeight = text.contentHeight || (Fonts.small)
              return textHeight + 16
            }
          }

          color: Colors.transparent
          property var subMenu: null

          Rectangle {
            width: parent.width - 16
            height: 1
            anchors.centerIn: parent
            visible: modelData?.isSeparator ?? false
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0.0
                color: Colors.transparent
              }
              GradientStop {
                position: 0.1
                color: Colors.accent
              }
              GradientStop {
                position: 0.9
                color: Colors.accent
              }
              GradientStop {
                position: 1.0
                color: Colors.transparent
              }
            }
          }

          Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Colors.accent : Colors.transparent
            radius: 10
            visible: !(modelData?.isSeparator ?? false)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              spacing: 8

              Text {
                id: text
                Layout.fillWidth: true
                color: (modelData?.enabled ?? true) ? (mouseArea.containsMouse ? Colors.base : Colors.text) : Colors.text
                text: modelData?.text !== "" ? modelData?.text.replace(/[\n\r]+/g, ' ') : "..."
                font.pointSize: Fonts.small
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
              }

              Image {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                source: modelData?.icon ?? ""
                visible: (modelData?.icon ?? "") !== ""
                fillMode: Image.PreserveAspectFit
              }

              Text {
                verticalAlignment: Text.AlignVCenter
                visible: modelData?.hasChildren ?? false
                color: (mouseArea.containsMouse ? Colors.base : Colors.text)

                text: {
                  const icon = modelData?.hasChildren ? "menu" : ""
                  if ((icon === undefined) || (icon === "")) {
                    return ""
                  }
                  if (Icons.get(icon) === undefined) {
                    console.warn("Icon", `"${icon}"`, "doesn't exist in the icons font")
                    return Icons.get(Icons.defaultIcon)
                  }
                  return Icons.get(icon)
                }
                font.family: Icons.fontFamily
                font.pointSize: Fonts.small
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              enabled: (modelData?.enabled ?? true) && !(modelData?.isSeparator ?? false) && root.visible

              onClicked: {
                if (modelData && !modelData.isSeparator && !modelData.hasChildren) {
                  modelData.triggered()
                  root.hideMenu()
                }
              }

              onEntered: {
                if (!root.visible)
                  return

                // Close all sibling submenus
                for (var i = 0; i < columnLayout.children.length; i++) {
                  const sibling = columnLayout.children[i]
                  if (sibling !== entry && sibling?.subMenu) {
                    sibling.subMenu.hideMenu()
                    sibling.subMenu.destroy()
                    sibling.subMenu = null
                  }
                }

                // Create submenu if needed
                if (modelData?.hasChildren) {
                  if (entry.subMenu) {
                    entry.subMenu.hideMenu()
                    entry.subMenu.destroy()
                  }

                  // Need a slight overlap so that menu don't close when moving the mouse to a submenu
                  const submenuWidth = menuWidth // Assuming a similar width as the parent
                  const overlap = 4 // A small overlap to bridge the mouse path

                  // Position with overlap
                  const anchorX = -submenuWidth + overlap

                  // Create submenu
                  entry.subMenu = Qt.createComponent("TrayMenu.qml").createObject(root, {
                                                                                    "menu": modelData,
                                                                                    "anchorItem": entry,
                                                                                    "anchorX": anchorX,
                                                                                    "anchorY": 0,
                                                                                    "isSubMenu": true,
                                                                                    "screen": root.screen
                                                                                  })

                  if (entry.subMenu) {
                    entry.subMenu.showAt(entry, anchorX, 0)
                  }
                }
              }

              onExited: {
                Qt.callLater(() => {
                               if (entry.subMenu && !entry.subMenu.isHovered) {
                                 entry.subMenu.hideMenu()
                                 entry.subMenu.destroy()
                                 entry.subMenu = null
                               }
                             })
              }
            }
          }

          Component.onDestruction: {
            if (subMenu) {
              subMenu.destroy()
              subMenu = null
            }
          }
        }
      }
    }
  }
}
