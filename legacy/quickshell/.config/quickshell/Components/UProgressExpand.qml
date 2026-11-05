import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Constants

Item {
    id: root

    required property string iconName
    property int iconSize: Style.fontSizeM
    property real maxValue: 100
    property real value: 100
    property string textValue: "" // override value in textDisplay if set
    property color fillColor: Colors.mPrimary
    property string textSuffix: ""
    property bool pointerCursor: true
    property bool expandOnValueChange: false
    property real hideTimeOut: 2000 // ms
    property bool forceExpand: false
    property bool _expand: forceExpand || mouseArea.containsMouse
    property bool _isFirst: true
    property bool disableHover: false
    property bool critical: false
    property color criticalColor: Colors.mRed
    readonly property real ratio: value / maxValue
    property color realColor: critical ? criticalColor : fillColor

    signal wheelUp()
    signal wheelDown()
    signal clicked()
    signal rightClicked()
    signal middleClicked()

    implicitHeight: Math.max(iconSize, textLabel.implicitHeight) + 12
    implicitWidth: height + textDisplay.implicitWidth

    Loader {
        id: connectionLoader

        active: expandOnValueChange

        sourceComponent: Connections {
            function onValueChanged() {
                // No need to expand (again) if already hovering
                if (mouseArea.containsMouse)
                    return ;

                // Skip first change (which is most likely initialization)
                if (root._isFirst) {
                    root._isFirst = false;
                    return ;
                }
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: pointerCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                root.clicked();
            else if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else if (mouse.button === Qt.MiddleButton)
                root.middleClicked();
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                root.wheelUp();
            else if (wheel.angleDelta.y < 0)
                root.wheelDown();
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            id: progressDisplay

            Layout.preferredHeight: root.height
            Layout.preferredWidth: root.height

            Canvas {
                id: progressCircle

                anchors.fill: parent
                anchors.centerIn: parent
                onPaint: {
                    var ctx = getContext("2d");
                    if (!ctx)
                        return ;

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

            UIcon {
                id: symbolIcon

                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconName: root.iconName
                iconSize: root.iconSize
                color: root.realColor
            }

        }

        Item {
            id: textDisplay

            implicitHeight: parent.height
            implicitWidth: root._expand ? textLabel.implicitWidth + 10 : 0
            clip: true

            UText {
                id: textLabel

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: (textValue || Math.round(root.value)) + root.textSuffix
                font.pointSize: Style.fontSizeS
                color: root.realColor
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
