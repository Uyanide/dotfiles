import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Constants

Item {
    id: root

    required property string symbol
    property real maxValue: 100
    property real value: 100
    property string textValue: "" // override value in textDisplay if set
    property color fillColor: Colors.primary
    property string textSuffix: ""
    property bool pointerCursor: true
    property bool expandOnValueChange: false
    property real hideTimeOut: 2000 // ms
    property bool forceExpand: false
    property bool _expand: forceExpand || mouseArea.containsMouse
    property bool disableHover: false
    property bool critical: false
    property color criticalColor: Colors.red
    readonly property real ratio: value / maxValue
    property color realColor: critical ? criticalColor : fillColor

    signal wheelUp()
    signal wheelDown()
    signal clicked()
    signal rightClicked()

    implicitHeight: parent.height - 5
    implicitWidth: parent.height + (_expand ? textDisplay.width : 0)

    Loader {
        id: connectionLoader

        active: expandOnValueChange

        sourceComponent: Connections {
            function onValueChanged() {
                root.forceExpand = true;
                hideTimer.restart();
            }

            target: root
        }

    }

    Timer {
        id: hideTimer

        interval: parent.hideTimeOut
        running: false
        repeat: false
        onTriggered: {
            root.forceExpand = false;
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: !disableHover
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: pointerCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                root.clicked();
            else if (mouse.button === Qt.RightButton)
                root.rightClicked();
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                root.wheelUp();
            else if (wheel.angleDelta.y < 0)
                root.wheelDown();
        }
    }

    RowLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        Item {
            id: progressDisplay

            Layout.preferredHeight: parent.height
            Layout.preferredWidth: parent.height

            Canvas {
                id: progressCircle

                anchors.fill: parent
                anchors.centerIn: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var centerX = width / 2;
                    var centerY = height / 2;
                    var radius = width / 2 - 3;
                    var startAngle = -Math.PI / 2;
                    var endAngle = startAngle - (2 * Math.PI * root.ratio);
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, endAngle, startAngle, false);
                    ctx.lineWidth = 3;
                    ctx.strokeStyle = root.realColor;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }

                Connections {
                    function onRatioChanged() {
                        progressCircle.requestPaint();
                    }

                    function onRealColorChanged() {
                        progressCircle.requestPaint();
                    }

                    target: root
                }

            }

            Text {
                id: symbolText

                anchors.fill: parent
                text: symbol
                font.family: Fonts.nerd
                font.pointSize: Fonts.icon
                color: root.realColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

        }

        Item {
            id: textDisplay

            implicitHeight: parent.height
            implicitWidth: root._expand ? textLabel.implicitWidth + 10 : 0
            clip: true

            Text {
                id: textLabel

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: (textValue || Math.round(root.value)) + root.textSuffix
                font.pointSize: Fonts.small
                font.family: Fonts.primary
                color: root.realColor
                opacity: root._expand ? 1 : 0
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.InOutCubic
                }

            }

        }

    }

    Behavior on realColor {
        ColorAnimation {
            duration: Style.animationNormal
            easing.type: Easing.InOutCubic
        }

    }

}
