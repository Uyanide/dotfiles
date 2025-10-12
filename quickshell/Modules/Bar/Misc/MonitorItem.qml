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
    property alias hovered: mouseArea.containsMouse
    readonly property real ratio: value / maxValue

    signal wheelUp()
    signal wheelDown()
    signal clicked()

    implicitHeight: parent.height - 5
    implicitWidth: parent.height + (hovered ? textDisplay.width : 0)

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
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
                    ctx.strokeStyle = root.fillColor;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }

                Connections {
                    function onRatioChanged() {
                        progressCircle.requestPaint();
                    }

                    function onFillColorChanged() {
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
                color: fillColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

        }

        Item {
            id: textDisplay

            implicitHeight: parent.height
            implicitWidth: root.hovered ? textLabel.implicitWidth + 10 : 0
            clip: true

            Text {
                id: textLabel

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: (textValue || Math.round(root.value)) + root.textSuffix
                font.pointSize: Fonts.small
                font.family: Fonts.primary
                color: root.fillColor
                opacity: root.hovered ? 1 : 0
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.InOutCubic
                }

            }

        }

    }

}
