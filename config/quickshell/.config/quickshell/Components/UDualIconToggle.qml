import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants

Rectangle {
    id: root

    property string currentValue: ""
    property string firstOptionValue: "1"
    property string firstOptionIcon: "1"
    property string secondOptionValue: "2"
    property string secondOptionIcon: "2"

    signal toggled(string value)

    implicitWidth: Style.baseWidgetSize * 2.8
    implicitHeight: Style.baseWidgetSize
    radius: Math.min(Style.radiusS, height / 2)
    color: Colors.mSurface

    Row {
        anchors.fill: parent
        spacing: Style.marginS / 2

        Rectangle {
            width: root.currentValue === root.firstOptionValue ? (parent.width - parent.spacing) * 0.65 : (parent.width - parent.spacing) * 0.35
            height: parent.height
            radius: Math.min(Style.radiusS, height / 2)
            color: root.currentValue === root.firstOptionValue ? Colors.mPrimary : "transparent"

            UIcon {
                anchors.centerIn: parent
                iconName: root.firstOptionIcon
                iconSize: Style.fontSizeL
                color: root.currentValue === root.firstOptionValue ? Colors.mOnPrimary : Colors.mOnSurface

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.toggled(root.firstOptionValue);
                }
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
            width: root.currentValue === root.secondOptionValue ? (parent.width - parent.spacing) * 0.65 : (parent.width - parent.spacing) * 0.35
            height: parent.height
            radius: Math.min(Style.radiusS, height / 2)
            color: root.currentValue === root.secondOptionValue ? Colors.mPrimary : "transparent"

            UIcon {
                anchors.centerIn: parent
                iconName: root.secondOptionIcon
                iconSize: Style.fontSizeL
                color: root.currentValue === root.secondOptionValue ? Colors.mOnPrimary : Colors.mOnSurface

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.toggled(root.secondOptionValue);
                }
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
