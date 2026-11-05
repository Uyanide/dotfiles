import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import qs.Constants

Slider {
    id: root

    property color fillColor: Colors.mPrimary
    property var cutoutColor: Colors.mSurface
    property bool snapAlways: true
    property real heightRatio: 0.7
    property string tooltipText
    property string tooltipDirection: "auto"
    property bool hovering: false
    readonly property color effectiveFillColor: enabled ? fillColor : Colors.mOutline
    readonly property real knobDiameter: Math.round((Style.baseWidgetSize * heightRatio) / 2) * 2
    readonly property real trackHeight: Math.round((knobDiameter * 0.4) / 2) * 2
    readonly property real trackRadius: Math.min(Style.radiusL, trackHeight / 2)
    readonly property real cutoutExtra: Math.round((Style.baseWidgetSize * 0.1) / 2) * 2

    padding: cutoutExtra / 2
    snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
    implicitHeight: Math.max(trackHeight, knobDiameter)

    background: Item {
        id: bgContainer

        readonly property real fillWidth: root.visualPosition * width

        x: root.leftPadding
        y: root.topPadding + Math.round((root.availableHeight - root.trackHeight) / 2)
        implicitWidth: Style.sliderWidth
        implicitHeight: root.trackHeight
        width: root.availableWidth
        height: root.trackHeight

        // Background track
        Shape {
            anchors.fill: parent
            visible: bgContainer.width > 0 && bgContainer.height > 0
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: bgPath

                readonly property real w: bgContainer.width
                readonly property real h: bgContainer.height
                readonly property real r: root.trackRadius

                strokeColor: Qt.alpha(Colors.mOutline, 0.5)
                strokeWidth: Style.borderS
                fillColor: Qt.alpha(Colors.mSurface, 0.5)
                startX: r
                startY: 0

                PathLine {
                    x: bgPath.w - bgPath.r
                    y: 0
                }

                PathArc {
                    x: bgPath.w
                    y: bgPath.r
                    radiusX: bgPath.r
                    radiusY: bgPath.r
                }

                PathLine {
                    x: bgPath.w
                    y: bgPath.h - bgPath.r
                }

                PathArc {
                    x: bgPath.w - bgPath.r
                    y: bgPath.h
                    radiusX: bgPath.r
                    radiusY: bgPath.r
                }

                PathLine {
                    x: bgPath.r
                    y: bgPath.h
                }

                PathArc {
                    x: 0
                    y: bgPath.h - bgPath.r
                    radiusX: bgPath.r
                    radiusY: bgPath.r
                }

                PathLine {
                    x: 0
                    y: bgPath.r
                }

                PathArc {
                    x: bgPath.r
                    y: 0
                    radiusX: bgPath.r
                    radiusY: bgPath.r
                }

            }

        }

        LinearGradient {
            id: fillGradient

            x1: 0
            y1: 0
            x2: root.availableWidth
            y2: 0

            GradientStop {
                position: 0
                color: Qt.darker(effectiveFillColor, 1.2)
            }

            GradientStop {
                position: 1
                color: effectiveFillColor
            }

        }

        // Active/filled track
        Shape {
            width: bgContainer.fillWidth
            height: bgContainer.height
            visible: bgContainer.fillWidth > 0 && bgContainer.height > 0
            preferredRendererType: Shape.CurveRenderer
            clip: true

            ShapePath {
                id: fillPath

                readonly property real fullWidth: root.availableWidth
                readonly property real h: root.trackHeight
                readonly property real r: root.trackRadius

                strokeColor: "transparent"
                fillGradient: fillGradient
                startX: r
                startY: 0

                PathLine {
                    x: fillPath.fullWidth - fillPath.r
                    y: 0
                }

                PathArc {
                    x: fillPath.fullWidth
                    y: fillPath.r
                    radiusX: fillPath.r
                    radiusY: fillPath.r
                }

                PathLine {
                    x: fillPath.fullWidth
                    y: fillPath.h - fillPath.r
                }

                PathArc {
                    x: fillPath.fullWidth - fillPath.r
                    y: fillPath.h
                    radiusX: fillPath.r
                    radiusY: fillPath.r
                }

                PathLine {
                    x: fillPath.r
                    y: fillPath.h
                }

                PathArc {
                    x: 0
                    y: fillPath.h - fillPath.r
                    radiusX: fillPath.r
                    radiusY: fillPath.r
                }

                PathLine {
                    x: 0
                    y: fillPath.r
                }

                PathArc {
                    x: fillPath.r
                    y: 0
                    radiusX: fillPath.r
                    radiusY: fillPath.r
                }

            }

        }

        // Circular cutout
        Rectangle {
            id: knobCutout

            implicitWidth: root.knobDiameter + root.cutoutExtra
            implicitHeight: root.knobDiameter + root.cutoutExtra
            radius: Math.min(Style.radiusL, width / 2)
            color: root.cutoutColor !== undefined ? root.cutoutColor : Colors.mSurface
            x: root.visualPosition * (root.availableWidth - root.knobDiameter) - root.cutoutExtra / 2
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    handle: Item {
        implicitWidth: knobDiameter
        implicitHeight: knobDiameter
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id: knob

            implicitWidth: knobDiameter
            implicitHeight: knobDiameter
            radius: Math.min(Style.radiusL, width / 2)
            color: root.pressed ? Colors.mHover : Colors.mSurface
            border.color: effectiveFillColor
            border.width: Style.borderL
            anchors.centerIn: parent

            Behavior on color {
                ColorAnimation {
                    duration: Style.animationFast
                }

            }

        }

        MouseArea {
            enabled: true
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.NoButton // Don't accept any mouse buttons - only hover
            propagateComposedEvents: true
            onEntered: {
                root.hovering = true;
                if (root.tooltipText)
                    TooltipService.show(knob, root.tooltipText, root.tooltipDirection);

            }
            onExited: {
                root.hovering = false;
                if (root.tooltipText)
                    TooltipService.hide();

            }
        }

        // Hide tooltip when slider is pressed (anywhere on the slider)
        Connections {
            function onPressedChanged() {
                if (root.pressed && root.tooltipText)
                    TooltipService.hide();

            }

            target: root
        }

    }

}
