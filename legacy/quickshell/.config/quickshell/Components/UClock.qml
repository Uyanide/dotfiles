import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Utils

Item {
    id: root

    property var now: Time.now
    // Style: "analog" or "digital"
    property string clockStyle: "analog"
    // Show seconds progress ring (digital only)
    property bool showProgress: true
    // Colors properties
    property color backgroundColor: Colors.mPrimary
    property color clockColor: Colors.mOnPrimary
    property color secondHandColor: Colors.mError
    property color progressColor: root.secondHandColor
    // Font size properties for digital clock
    property real hoursFontSize: Style.fontSizeXS
    property real minutesFontSize: Style.fontSizeXXS
    property int hoursFontWeight: Style.fontWeightBold
    property int minutesFontWeight: Style.fontWeightBold
    // Scale ratio for canvas line widths (used by desktop widget scaling)
    property real scaleRatio: 1

    height: Math.round((Style.fontSizeXXXL * 1.9) / 2) * 2
    width: root.height

    Loader {
        id: clockLoader

        anchors.fill: parent
        sourceComponent: {
            if (root.clockStyle === "analog")
                return analogClockComponent;

            if (root.clockStyle === "binary")
                return binaryClockComponent;

            return digitalClockComponent;
        }
        onLoaded: {
            item.now = Qt.binding(function() {
                return root.now;
            });
            item.backgroundColor = Qt.binding(function() {
                return root.backgroundColor;
            });
            item.clockColor = Qt.binding(function() {
                return root.clockColor;
            });
            if (item.hasOwnProperty("secondHandColor"))
                item.secondHandColor = Qt.binding(function() {
                return root.secondHandColor;
            });

            if (item.hasOwnProperty("progressColor"))
                item.progressColor = Qt.binding(function() {
                return root.progressColor;
            });

            if (item.hasOwnProperty("hoursFontSize"))
                item.hoursFontSize = Qt.binding(function() {
                return root.hoursFontSize;
            });

            if (item.hasOwnProperty("minutesFontSize"))
                item.minutesFontSize = Qt.binding(function() {
                return root.minutesFontSize;
            });

            if ("hoursFontWeight" in item)
                item.hoursFontWeight = Qt.binding(function() {
                return root.hoursFontWeight;
            });

            if ("minutesFontWeight" in item)
                item.minutesFontWeight = Qt.binding(function() {
                return root.minutesFontWeight;
            });

            if (item.hasOwnProperty("scaleRatio"))
                item.scaleRatio = Qt.binding(function() {
                return root.scaleRatio;
            });

            if ("showProgress" in item)
                item.showProgress = Qt.binding(function() {
                return root.showProgress;
            });

        }
    }

    Component {
        id: analogClockComponent

        UClockAnalog {
        }

    }

    Component {
        id: digitalClockComponent

        UClockDigital {
        }

    }

    Component {
        id: binaryClockComponent

        UClockBinary {
        }

    }

    // Analog Clock Component
    component UClockAnalog: Item {
        property var now
        property color backgroundColor: Colors.mPrimary
        property color clockColor: Colors.mOnPrimary
        property color secondHandColor: Colors.mError
        property real scaleRatio: 1

        anchors.fill: parent

        Canvas {
            id: clockCanvas

            anchors.fill: parent
            onPaint: {
                var currentTime = Time.now;
                var hours = currentTime.getHours();
                var minutes = currentTime.getMinutes();
                var seconds = currentTime.getSeconds();
                const markAlpha = 0.7;
                var ctx = getContext("2d");
                ctx.reset();
                ctx.translate(width / 2, height / 2);
                var radius = Math.min(width, height) / 2;
                // Hour marks
                ctx.strokeStyle = Qt.alpha(clockColor, markAlpha);
                ctx.lineWidth = 2 * scaleRatio;
                var scaleFactor = 0.7;
                for (var i = 0; i < 12; i++) {
                    var scaleFactor = 0.8;
                    if (i % 3 === 0)
                        scaleFactor = 0.65;

                    ctx.save();
                    ctx.rotate(i * Math.PI / 6);
                    ctx.beginPath();
                    ctx.moveTo(0, -radius * scaleFactor);
                    ctx.lineTo(0, -radius);
                    ctx.stroke();
                    ctx.restore();
                }
                // Hour hand
                ctx.save();
                var hourAngle = (hours % 12 + minutes / 60) * Math.PI / 6;
                ctx.rotate(hourAngle);
                ctx.strokeStyle = clockColor;
                ctx.lineWidth = 3 * scaleRatio;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(0, -radius * 0.6);
                ctx.stroke();
                ctx.restore();
                // Minute hand
                ctx.save();
                var minuteAngle = (minutes + seconds / 60) * Math.PI / 30;
                ctx.rotate(minuteAngle);
                ctx.strokeStyle = clockColor;
                ctx.lineWidth = 2 * scaleRatio;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(0, -radius * 0.9);
                ctx.stroke();
                ctx.restore();
                // Second hand
                ctx.save();
                var secondAngle = seconds * Math.PI / 30;
                ctx.rotate(secondAngle);
                ctx.strokeStyle = secondHandColor;
                ctx.lineWidth = 1.6 * scaleRatio;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(0, -radius);
                ctx.stroke();
                ctx.restore();
                // Center dot
                ctx.beginPath();
                ctx.arc(0, 0, 3 * scaleRatio, 0, 2 * Math.PI);
                ctx.fillStyle = clockColor;
                ctx.fill();
            }
            Component.onCompleted: requestPaint()

            Connections {
                function onNowChanged() {
                    clockCanvas.requestPaint();
                }

                target: Time
            }

        }

    }

    // Digital Clock Component
    component UClockDigital: Item {
        property var now
        property color backgroundColor: Colors.mPrimary
        property color clockColor: Colors.mOnPrimary
        property color progressColor: Colors.mError
        property real hoursFontSize: Style.fontSizeXS
        property real minutesFontSize: Style.fontSizeXXS
        property int hoursFontWeight: Style.fontWeightBold
        property int minutesFontWeight: Style.fontWeightBold
        property real scaleRatio: 1
        property bool showProgress: true

        anchors.fill: parent

        // Digital clock's seconds circular progress
        Canvas {
            id: secondsProgress

            property real progress: now.getSeconds() / 60

            anchors.fill: parent
            visible: showProgress
            onProgressChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                var centerX = width / 2;
                var centerY = height / 2;
                var radius = Math.min(width, height) / 2 - 3 * scaleRatio;
                ctx.reset();
                // Background circle
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                ctx.lineWidth = 2.5 * scaleRatio;
                ctx.strokeStyle = Qt.alpha(clockColor, 0.15);
                ctx.stroke();
                // Progress arc
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI);
                ctx.lineWidth = 2.5 * scaleRatio;
                ctx.strokeStyle = progressColor;
                ctx.lineCap = "round";
                ctx.stroke();
            }

            Connections {
                function onNowChanged() {
                    const total = now.getSeconds() * 1000 + now.getMilliseconds();
                    secondsProgress.progress = total / 60000;
                }

                target: Time
            }

        }

        // Digital clock
        ColumnLayout {
            anchors.centerIn: parent
            spacing: -Style.marginXXS

            UText {
                text: Qt.formatTime(now, "HH")
                pointSize: hoursFontSize
                font.weight: hoursFontWeight
                color: clockColor
                Layout.alignment: Qt.AlignHCenter
            }

            UText {
                text: Qt.formatTime(now, "mm")
                pointSize: minutesFontSize
                font.weight: minutesFontWeight
                color: clockColor
                Layout.alignment: Qt.AlignHCenter
            }

        }

    }

    // Binary Clock Component
    component UClockBinary: Item {
        // BCD (Binary Coded Decimal) Format:
        // H1 H2 : M1 M2 : S1 S2
        // H1 (tens): 0-2 (2 bits)
        // H2 (ones): 0-9 (4 bits)
        // M1 (tens): 0-5 (3 bits)
        // M2 (ones): 0-9 (4 bits)
        // S1 (tens): 0-5 (3 bits)
        // S2 (ones): 0-9 (4 bits)

        property var now
        property color backgroundColor
        property color clockColor: Colors.mOnPrimary
        readonly property int h: now.getHours()
        readonly property int m: now.getMinutes()
        readonly property int s: now.getSeconds()

        anchors.fill: parent

        RowLayout {
            anchors.centerIn: parent
            spacing: parent.width * 0.05

            // Hours
            RowLayout {
                spacing: parent.parent.width * 0.02

                BinaryColumn {
                    value: Math.floor(h / 10)
                    bits: 2
                    dotSize: root.width * 0.08
                    activeColor: clockColor
                    Layout.alignment: Qt.AlignBottom
                }

                BinaryColumn {
                    value: h % 10
                    bits: 4
                    dotSize: root.width * 0.08
                    activeColor: clockColor
                    Layout.alignment: Qt.AlignBottom
                }

            }

            // Minutes
            RowLayout {
                spacing: parent.parent.width * 0.02

                BinaryColumn {
                    value: Math.floor(m / 10)
                    bits: 3
                    dotSize: root.width * 0.08
                    activeColor: clockColor
                    Layout.alignment: Qt.AlignBottom
                }

                BinaryColumn {
                    value: m % 10
                    bits: 4
                    dotSize: root.width * 0.08
                    activeColor: clockColor
                    Layout.alignment: Qt.AlignBottom
                }

            }

            // Seconds
            RowLayout {
                spacing: parent.parent.width * 0.02

                BinaryColumn {
                    value: Math.floor(s / 10)
                    bits: 3
                    dotSize: root.width * 0.08
                    activeColor: clockColor
                    Layout.alignment: Qt.AlignBottom
                }

                BinaryColumn {
                    value: s % 10
                    bits: 4
                    dotSize: root.width * 0.08
                    activeColor: clockColor
                    Layout.alignment: Qt.AlignBottom
                }

            }

        }

    }

    component BinaryColumn: Column {
        property int value: 0
        property int bits: 4
        property real dotSize: 10
        property color activeColor: "white"

        spacing: dotSize * 0.4

        Repeater {
            model: bits

            Rectangle {
                property int bitIndex: (bits - 1) - index
                property bool isActive: (value >> bitIndex) & 1

                width: dotSize
                height: dotSize
                radius: dotSize / 2
                color: isActive ? activeColor : Qt.alpha(activeColor, 0.2)

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

        }

    }

}
