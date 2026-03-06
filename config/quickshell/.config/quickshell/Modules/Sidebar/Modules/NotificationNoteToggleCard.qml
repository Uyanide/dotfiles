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

        Rectangle {
            id: toggleGroup

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Style.baseWidgetSize * 2.8
            Layout.preferredHeight: Style.baseWidgetSize
            radius: Math.min(Style.radiusS, height / 2)
            color: Colors.mSurface

            Row {
                anchors.fill: parent
                spacing: Style.marginS / 2

                Rectangle {
                    id: btnNotifications

                    width: root.currentPanel === "notifications" ? (parent.width - parent.spacing) * 0.65 : (parent.width - parent.spacing) * 0.35
                    height: parent.height
                    radius: Math.min(Style.radiusS, height / 2)
                    color: root.currentPanel === "notifications" ? Colors.mPrimary : "transparent"

                    UIcon {
                        anchors.centerIn: parent
                        iconName: "bell"
                        iconSize: Style.fontSizeL
                        color: root.currentPanel === "notifications" ? Colors.mOnPrimary : Colors.mOnSurface

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: ShellState.rightSiderbarTab = "notifications"
                        cursorShape: Qt.PointingHandCursor
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                }

                Rectangle {
                    id: btnNotes

                    width: root.currentPanel === "notes" ? (parent.width - parent.spacing) * 0.65 : (parent.width - parent.spacing) * 0.35
                    height: parent.height
                    radius: Math.min(Style.radiusS, height / 2)
                    color: root.currentPanel === "notes" ? Colors.mPrimary : "transparent"

                    UIcon {
                        anchors.centerIn: parent
                        iconName: "notes"
                        iconSize: Style.fontSizeL
                        color: root.currentPanel === "notes" ? Colors.mOnPrimary : Colors.mOnSurface

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: ShellState.rightSiderbarTab = "notes"
                        cursorShape: Qt.PointingHandCursor
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                }

            }

        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NotificationHistoryCard {
                anchors.fill: parent
                visible: root.currentPanel === "notifications"
            }

            NoteCard {
                anchors.fill: parent
                visible: root.currentPanel === "notes"
            }

        }

    }

}
