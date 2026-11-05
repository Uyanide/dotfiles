import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Constants
import qs.Utils
import qs.Components

PopupWindow {
  id: root
  property QsMenuHandle menu
  property var anchorItem: null
  property real anchorX
  property real anchorY
  property bool isSubMenu: false
  property ShellScreen screen

  readonly property int menuWidth: 180

  implicitWidth: menuWidth

  // Use the content height of the Flickable for implicit height
  implicitHeight: Math.min(screen ? screen.height * 0.9 : Screen.height * 0.9, flickable.contentHeight + (Style.marginS * 2))
  visible: false
  color: Colors.transparent
  anchor.item: anchorItem
  anchor.rect.x: anchorX
  anchor.rect.y: anchorY - (isSubMenu ? 0 : 4)

  function showAt(item, x, y) {
    if (!item) {
      Logger.warn("TrayMenu", "AnchorItem is undefined, won't show menu.");
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

  function closeSiblingSubMenus(currentEntry) {
    for (var i = 0; i < columnLayout.children.length; i++) {
      const sibling = columnLayout.children[i]
      if (sibling !== currentEntry && sibling?.subMenu) {
        sibling.subMenu.hideMenu()
        sibling.subMenu.destroy()
        sibling.subMenu = null
      }
    }
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
    color: Colors.mSurface
    border.color: Colors.mPrimary
    border.width: 2
    radius: Style.radiusM
  }

  Flickable {
    id: flickable
    anchors.fill: parent
    anchors.margins: Style.marginS
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
              const textHeight = text.contentHeight || (Style.fontSizeS * 1.2)
              return Math.max(28, textHeight + (Style.marginS * 2))
            }
          }

          color: Colors.transparent
          property var subMenu: null

          UDivider {
            anchors.centerIn: parent
            width: parent.width - (Style.marginM * 2)
            visible: modelData?.isSeparator ?? false
          }

          Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Colors.mPrimary : Colors.transparent
            radius: Style.radiusS
            visible: !(modelData?.isSeparator ?? false)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.marginM
              anchors.rightMargin: Style.marginM
              spacing: Style.marginS

              UText {
                id: text
                Layout.fillWidth: true
                color: (modelData?.enabled ?? true) ? (mouseArea.containsMouse ? Colors.mOnPrimary : Colors.mOnSurface) : Colors.mOnSurfaceVariant
                text: modelData?.text !== "" ? modelData?.text.replace(/[\n\r]+/g, ' ') : "..."
                pointSize: Style.fontSizeS
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                family: Fonts.sans
              }

              IconImage {
                Layout.preferredWidth: Style.marginL
                Layout.preferredHeight: Style.marginL
                source: modelData?.icon ?? ""
                visible: (modelData?.icon ?? "") !== ""
              }

              UIcon {
                iconName: modelData?.hasChildren ? "menu" : ""
                iconSize: Style.fontSizeS
                verticalAlignment: Text.AlignVCenter
                visible: modelData?.hasChildren ?? false
                color: (mouseArea.containsMouse ? Colors.mOnPrimary : Colors.mOnSurface)
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              enabled: (modelData?.enabled ?? true) && !(modelData?.isSeparator ?? false) && root.visible
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                if (!modelData || modelData.isSeparator) {
                  return
                }

                if (modelData.hasChildren) {
                  if (entry.subMenu) {
                    entry.subMenu.hideMenu()
                    entry.subMenu.destroy()
                    entry.subMenu = null
                    return
                  }

                  root.closeSiblingSubMenus(entry)

                  const submenuWidth = menuWidth
                  const overlap = 12
                  const subAnchorX = -submenuWidth + overlap

                  entry.subMenu = Qt.createComponent("TrayMenu.qml").createObject(root, {
                                                                                    "menu": modelData,
                                                                                    "anchorItem": entry,
                                                                                    "anchorX": subAnchorX,
                                                                                    "anchorY": 0,
                                                                                    "isSubMenu": true,
                                                                                    "screen": root.screen
                                                                                  })

                  if (entry.subMenu) {
                    entry.subMenu.showAt(entry, subAnchorX, 0)
                  }
                  return
                }

                if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton) {
                  modelData.triggered()
                  root.hideMenu()
                }
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
