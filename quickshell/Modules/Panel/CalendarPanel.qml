import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Constants
import qs.Noctalia
import qs.Services
import qs.Utils

NPanel {
    id: root

    preferredWidth: 400
    preferredHeight: 520

    panelContent: ColumnLayout {
        id: content

        readonly property int firstDayOfWeek: Qt.locale().firstDayOfWeek
        property bool isCurrentMonth: checkIsCurrentMonth()
        readonly property bool weatherReady: (LocationService.data.weather !== null)

        function checkIsCurrentMonth() {
            return (Time.date.getMonth() === grid.month) && (Time.date.getFullYear() === grid.year);
        }

        function getISOWeekNumber(date) {
            const target = new Date(date.getTime());
            target.setHours(0, 0, 0, 0);
            const dayOfWeek = target.getDay() || 7;
            target.setDate(target.getDate() + 4 - dayOfWeek);
            const yearStart = new Date(target.getFullYear(), 0, 1);
            const weekNumber = Math.ceil(((target - yearStart) / 8.64e+07 + 1) / 7);
            return weekNumber;
        }

        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        Connections {
            function onDateChanged() {
                isCurrentMonth = checkIsCurrentMonth();
            }

            target: Time
        }

        // Combined blue banner with date/time and weather summary
        NBox {
            Layout.fillWidth: true
            Layout.preferredHeight: blueColumn.implicitHeight + Style.marginM * 2

            ColumnLayout {
                id: blueColumn

                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: 0

                // Combined layout for weather icon, date, and weather text
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    spacing: Style.marginS

                    // Weather icon and temperature
                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Style.marginXXS

                        NIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: weatherReady ? LocationService.weatherSymbolFromCode(LocationService.data.weather.current_weather.weathercode) : "cloud"
                            pointSize: Style.fontSizeXXL
                            color: Colors.text
                        }

                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                if (!weatherReady)
                                    return "";

                                var temp = LocationService.data.weather.current_weather.temperature;
                                var suffix = "C";
                                temp = Math.round(temp);
                                return `${temp}°${suffix}`;
                            }
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightBold
                            color: Colors.text
                        }

                    }

                    // Today day number
                    NText {
                        visible: content.isCurrentMonth
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                        text: Time.date.getDate()
                        pointSize: Style.fontSizeXXXL * 1.5
                        font.weight: Style.fontWeightBold
                        color: Colors.text
                    }

                    Item {
                        visible: !content.isCurrentMonth
                    }

                    // Month, year, location
                    ColumnLayout {
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                        spacing: -Style.marginXS

                        RowLayout {
                            spacing: 0

                            NText {
                                text: Qt.locale().monthName(grid.month, Locale.LongFormat).toUpperCase()
                                pointSize: Style.fontSizeXL * 1.2
                                font.weight: Style.fontWeightBold
                                color: Colors.text
                                Layout.alignment: Qt.AlignBaseline
                                Layout.maximumWidth: 150
                                elide: Text.ElideRight
                            }

                            NText {
                                text: ` ${grid.year}`
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightBold
                                color: Qt.alpha(Colors.text, 0.7)
                                Layout.alignment: Qt.AlignBaseline
                            }

                        }

                        RowLayout {
                            spacing: 0

                            NText {
                                text: {
                                    if (!weatherReady)
                                        return "Weather unavailable";

                                    const chunks = LocationService.data.name.split(",");
                                    return chunks[0];
                                }
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightMedium
                                color: Colors.text
                                Layout.maximumWidth: 150
                                elide: Text.ElideRight
                            }

                            NText {
                                text: weatherReady ? ` (${LocationService.data.weather.timezone_abbreviation})` : ""
                                pointSize: Style.fontSizeXS
                                font.weight: Style.fontWeightMedium
                                color: Qt.alpha(Colors.text, 0.7)
                            }

                        }

                    }

                    // Spacer between date and clock
                    Item {
                        Layout.fillWidth: true
                    }

                    // Digital clock with circular progress
                    Item {
                        width: Style.fontSizeXXXL * 1.9
                        height: Style.fontSizeXXXL * 1.9
                        Layout.alignment: Qt.AlignVCenter

                        // Seconds circular progress
                        Canvas {
                            id: secondsProgress

                            property real progress: Time.date.getSeconds() / 60

                            anchors.fill: parent
                            onProgressChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = Math.min(width, height) / 2 - 3;
                                ctx.reset();
                                // Background circle
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                ctx.lineWidth = 2.5;
                                ctx.strokeStyle = Qt.alpha(Colors.text, 0.15);
                                ctx.stroke();
                                // Progress arc
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI);
                                ctx.lineWidth = 2.5;
                                ctx.strokeStyle = Colors.text;
                                ctx.lineCap = "round";
                                ctx.stroke();
                            }

                            Connections {
                                function onDateChanged() {
                                    secondsProgress.progress = Time.date.getSeconds() / 60;
                                }

                                target: Time
                            }

                        }

                        // Digital clock
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: -Style.marginXXS

                            NText {
                                text: {
                                    var t = Qt.locale().toString(new Date(), "HH");
                                    return t.split(" ")[0];
                                }
                                pointSize: Style.fontSizeXS
                                font.weight: Style.fontWeightBold
                                color: Colors.text
                                family: Fonts.sans
                                Layout.alignment: Qt.AlignHCenter
                            }

                            NText {
                                text: Qt.formatTime(Time.date, "mm")
                                pointSize: Style.fontSizeXXS
                                font.weight: Style.fontWeightBold
                                color: Colors.text
                                family: Fonts.sans
                                Layout.alignment: Qt.AlignHCenter
                            }

                        }

                    }

                }

            }

        }

        // 6-day forecast (outside blue banner)
        RowLayout {
            visible: weatherReady
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Style.marginL

            Repeater {
                model: weatherReady ? Math.min(6, LocationService.data.weather.daily.time.length) : 0

                delegate: ColumnLayout {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.marginS

                    NText {
                        text: {
                            var weatherDate = new Date(LocationService.data.weather.daily.time[index].replace(/-/g, "/"));
                            return Qt.locale().toString(weatherDate, "ddd");
                        }
                        color: Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightMedium
                        Layout.alignment: Qt.AlignHCenter
                    }

                    NIcon {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        icon: LocationService.weatherSymbolFromCode(LocationService.data.weather.daily.weathercode[index])
                        pointSize: Style.fontSizeXXL * 1.5
                        color: LocationService.weatherColorFromCode(LocationService.data.weather.daily.weathercode[index])
                    }

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            var max = LocationService.data.weather.daily.temperature_2m_max[index];
                            var min = LocationService.data.weather.daily.temperature_2m_min[index];
                            max = Math.round(max);
                            min = Math.round(min);
                            return `${max}°/${min}°`;
                        }
                        pointSize: Style.fontSizeXS
                        color: Colors.text
                        font.weight: Style.fontWeightMedium
                    }

                }

            }

        }

        // Loading indicator for weather
        RowLayout {
            visible: !weatherReady
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            NBusyIndicator {
            }

        }

        // Spacer
        Item {
        }

        // Navigation and divider
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NDivider {
                Layout.fillWidth: true
            }

            NIconButton {
                icon: "chevron-left"
                colorBg: Color.transparent
                colorBorder: Color.transparent
                colorBorderHover: Color.transparent
                onClicked: {
                    let newDate = new Date(grid.year, grid.month - 1, 1);
                    grid.year = newDate.getFullYear();
                    grid.month = newDate.getMonth();
                    content.isCurrentMonth = content.checkIsCurrentMonth();
                }
            }

            NIconButton {
                icon: "calendar"
                colorBg: Color.transparent
                colorBorder: Color.transparent
                colorBorderHover: Color.transparent
                onClicked: {
                    grid.month = Time.date.getMonth();
                    grid.year = Time.date.getFullYear();
                    content.isCurrentMonth = true;
                }
            }

            NIconButton {
                icon: "chevron-right"
                colorBg: Color.transparent
                colorBorder: Color.transparent
                colorBorderHover: Color.transparent
                onClicked: {
                    let newDate = new Date(grid.year, grid.month + 1, 1);
                    grid.year = newDate.getFullYear();
                    grid.month = newDate.getMonth();
                    content.isCurrentMonth = content.checkIsCurrentMonth();
                }
            }

        }

        // Names of days of the week
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Item {
                Layout.preferredWidth: visible ? Style.baseWidgetSize * 0.7 : 0
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rows: 1
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: 7

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Style.baseWidgetSize * 0.6

                        NText {
                            anchors.centerIn: parent
                            text: {
                                let dayIndex = (content.firstDayOfWeek + index) % 7;
                                const dayNames = ["S", "M", "T", "W", "T", "F", "S"];
                                return dayNames[dayIndex];
                            }
                            color: Color.mPrimary
                            pointSize: Style.fontSizeS
                            font.weight: Style.fontWeightBold
                            horizontalAlignment: Text.AlignHCenter
                        }

                    }

                }

            }

        }

        // Grid with weeks and days
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Column of week numbers
            ColumnLayout {
                Layout.preferredWidth: visible ? Style.baseWidgetSize * 0.7 : 0
                Layout.fillHeight: true
                spacing: 0

                Repeater {
                    model: 6

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        NText {
                            anchors.centerIn: parent
                            color: Color.mOutline
                            pointSize: Style.fontSizeXXS
                            font.weight: Style.fontWeightMedium
                            text: {
                                let firstOfMonth = new Date(grid.year, grid.month, 1);
                                let firstDayOfWeek = content.firstDayOfWeek;
                                let firstOfMonthDayOfWeek = firstOfMonth.getDay();
                                let daysBeforeFirst = (firstOfMonthDayOfWeek - firstDayOfWeek + 7) % 7;
                                if (daysBeforeFirst === 0)
                                    daysBeforeFirst = 7;

                                let gridStartDate = new Date(grid.year, grid.month, 1 - daysBeforeFirst);
                                let rowStartDate = new Date(gridStartDate);
                                rowStartDate.setDate(gridStartDate.getDate() + (index * 7));
                                let thursday = new Date(rowStartDate);
                                if (firstDayOfWeek === 0) {
                                    thursday.setDate(rowStartDate.getDate() + 4);
                                } else if (firstDayOfWeek === 1) {
                                    thursday.setDate(rowStartDate.getDate() + 3);
                                } else {
                                    let daysToThursday = (4 - firstDayOfWeek + 7) % 7;
                                    thursday.setDate(rowStartDate.getDate() + daysToThursday);
                                }
                                return `${getISOWeekNumber(thursday)}`;
                            }
                        }

                    }

                }

            }

            // Days Grid
            MonthGrid {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.marginXXS
                month: Time.date.getMonth()
                year: Time.date.getFullYear()
                locale: Qt.locale()

                delegate: Item {
                    Rectangle {
                        width: Style.baseWidgetSize * 0.9
                        height: Style.baseWidgetSize * 0.9
                        anchors.centerIn: parent
                        radius: Style.radiusM
                        color: model.today ? Color.mSecondary : Color.transparent

                        NText {
                            anchors.centerIn: parent
                            text: model.day
                            color: {
                                if (model.today)
                                    return Color.mOnSecondary;

                                if (model.month === grid.month)
                                    return Color.mOnSurface;

                                return Color.mOnSurfaceVariant;
                            }
                            opacity: model.month === grid.month ? 1 : 0.4
                            pointSize: Style.fontSizeM
                            font.weight: model.today ? Style.fontWeightBold : Style.fontWeightMedium
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationFast
                            }

                        }

                    }

                }

            }

        }

    }

}
