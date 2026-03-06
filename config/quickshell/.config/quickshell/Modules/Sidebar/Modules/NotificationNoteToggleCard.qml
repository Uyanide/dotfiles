import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

Item {
    id: root

    property string currentPanel: ShellState.rightSiderbarTab // "notifications", "notes"

    ColumnLayout {
        anchors.fill: parent
        spacing: Style.marginM

        UDualIconToggle {
            id: toggleGroup

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Style.baseWidgetSize * 2.8
            Layout.preferredHeight: Style.baseWidgetSize
            firstOptionValue: "notifications"
            firstOptionIcon: "bell"
            secondOptionValue: "notes"
            secondOptionIcon: "notes"
            currentValue: root.currentPanel
            onToggled: (value) => {
                ShellState.rightSiderbarTab = value;
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            NotificationHistoryCard {
                width: parent.width
                height: parent.height
                x: root.currentPanel === "notifications" ? 0 : -width
                opacity: root.currentPanel === "notifications" ? 1 : 0

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

            }

            NoteCard {
                width: parent.width
                height: parent.height
                x: root.currentPanel === "notes" ? 0 : width
                opacity: root.currentPanel === "notes" ? 1 : 0

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

}
