import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Utils

// Calendar month grid with navigation
UBox {
    id: root

    // Internal state - independent from header
    readonly property var now: Time.now
    property int calendarMonth: now.getMonth()
    property int calendarYear: now.getFullYear()
    readonly property var locale: Qt.locale("en")
    readonly property int firstDayOfWeek: locale.firstDayOfWeek

    // Helper function to calculate ISO week number
    function getISOWeekNumber(date) {
        const target = new Date(date.valueOf());
        const dayNr = (date.getDay() + 6) % 7;
        target.setDate(target.getDate() - dayNr + 3);
        const firstThursday = new Date(target.getFullYear(), 0, 4);
        const diff = target - firstThursday;
        const oneWeek = 1000 * 60 * 60 * 24 * 7;
        const weekNumber = 1 + Math.round(diff / oneWeek);
        return weekNumber;
    }

    // Helper function to check if an event is all-day
    function isAllDayEvent(event) {
        const duration = event.end - event.start;
        const startDate = new Date(event.start * 1000);
        const isAtMidnight = startDate.getHours() === 0 && startDate.getMinutes() === 0;
        return duration === 86400 && isAtMidnight;
    }

    // Navigation functions
    function navigateToPreviousMonth() {
        let newDate = new Date(root.calendarYear, root.calendarMonth - 1, 1);
        root.calendarYear = newDate.getFullYear();
        root.calendarMonth = newDate.getMonth();
        const now = new Date();
        const monthStart = new Date(root.calendarYear, root.calendarMonth, 1);
        const monthEnd = new Date(root.calendarYear, root.calendarMonth + 1, 0);
        const daysBehind = Math.max(0, Math.ceil((now - monthStart) / (24 * 60 * 60 * 1000)));
        const daysAhead = Math.max(0, Math.ceil((monthEnd - now) / (24 * 60 * 60 * 1000)));
    }

    function navigateToNextMonth() {
        let newDate = new Date(root.calendarYear, root.calendarMonth + 1, 1);
        root.calendarYear = newDate.getFullYear();
        root.calendarMonth = newDate.getMonth();
        const now = new Date();
        const monthStart = new Date(root.calendarYear, root.calendarMonth, 1);
        const monthEnd = new Date(root.calendarYear, root.calendarMonth + 1, 0);
        const daysBehind = Math.max(0, Math.ceil((now - monthStart) / (24 * 60 * 60 * 1000)));
        const daysAhead = Math.max(0, Math.ceil((monthEnd - now) / (24 * 60 * 60 * 1000)));
    }

    Layout.fillWidth: true
    implicitHeight: calendarContent.implicitHeight + Style.marginM * 2
    compact: true

    // Wheel handler for month navigation
    WheelHandler {
        id: wheelHandler

        target: root
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (event.angleDelta.y > 0) {
                // Scroll up - go to previous month
                root.navigateToPreviousMonth();
                event.accepted = true;
            } else if (event.angleDelta.y < 0) {
                // Scroll down - go to next month
                root.navigateToNextMonth();
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        id: calendarContent

        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        // Navigation row
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Item {
                Layout.preferredWidth: Style.marginS
            }

            UText {
                text: locale.monthName(root.calendarMonth, Locale.LongFormat).toUpperCase() + " " + root.calendarYear
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: Colors.mOnSurface
            }

            UDivider {
                Layout.fillWidth: true
            }

            UIconButton {
                iconName: "chevron-left"
                onClicked: root.navigateToPreviousMonth()
            }

            UIconButton {
                iconName: "calendar"
                onClicked: {
                    root.calendarMonth = root.now.getMonth();
                    root.calendarYear = root.now.getFullYear();
                }
            }

            UIconButton {
                iconName: "chevron-right"
                onClicked: root.navigateToNextMonth()
            }

        }

        // Day names header
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
                        Layout.preferredHeight: Style.fontSizeS * 2

                        UText {
                            anchors.centerIn: parent
                            text: {
                                let dayIndex = (root.firstDayOfWeek + index) % 7;
                                const dayName = locale.dayName(dayIndex, Locale.ShortFormat);
                                return dayName.substring(0, 2).toUpperCase();
                            }
                            color: Colors.mPrimary
                            pointSize: Style.fontSizeS
                            font.weight: Style.fontWeightBold
                            horizontalAlignment: Text.AlignHCenter
                        }

                    }

                }

            }

        }

        // Calendar grid with week numbers
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            // Week numbers column
            ColumnLayout {
                property var weekNumbers: {
                    if (!grid.daysModel || grid.daysModel.length === 0)
                        return [];

                    const weeks = [];
                    const numWeeks = Math.ceil(grid.daysModel.length / 7);
                    for (var i = 0; i < numWeeks; i++) {
                        const dayIndex = i * 7;
                        if (dayIndex < grid.daysModel.length) {
                            const weekDay = grid.daysModel[dayIndex];
                            const date = new Date(weekDay.year, weekDay.month, weekDay.day);
                            let thursday = new Date(date);
                            if (root.firstDayOfWeek === 0) {
                                thursday.setDate(date.getDate() + 4);
                            } else if (root.firstDayOfWeek === 1) {
                                thursday.setDate(date.getDate() + 3);
                            } else {
                                let daysToThursday = (4 - root.firstDayOfWeek + 7) % 7;
                                thursday.setDate(date.getDate() + daysToThursday);
                            }
                            weeks.push(root.getISOWeekNumber(thursday));
                        }
                    }
                    return weeks;
                }

                Layout.preferredWidth: Style.baseWidgetSize * 0.7
                Layout.alignment: Qt.AlignTop
                spacing: Style.marginXXS

                Repeater {
                    model: parent.weekNumbers

                    Item {
                        Layout.preferredWidth: Style.baseWidgetSize * 0.7
                        Layout.preferredHeight: Style.baseWidgetSize * 0.9

                        UText {
                            anchors.centerIn: parent
                            color: Qt.alpha(Colors.mPrimary, 0.7)
                            pointSize: Style.fontSizeXXS
                            text: modelData
                        }

                    }

                }

            }

            // Calendar grid
            GridLayout {
                id: grid

                property int month: root.calendarMonth
                property int year: root.calendarYear
                property var daysModel: {
                    const firstOfMonth = new Date(year, month, 1);
                    const lastOfMonth = new Date(year, month + 1, 0);
                    const daysInMonth = lastOfMonth.getDate();
                    const firstDayOfWeek = root.firstDayOfWeek;
                    const firstOfMonthDayOfWeek = firstOfMonth.getDay();
                    let daysBefore = (firstOfMonthDayOfWeek - firstDayOfWeek + 7) % 7;
                    const lastOfMonthDayOfWeek = lastOfMonth.getDay();
                    const daysAfter = (firstDayOfWeek - lastOfMonthDayOfWeek - 1 + 7) % 7;
                    const days = [];
                    const today = new Date();
                    // Previous month days
                    const prevMonth = new Date(year, month, 0);
                    const prevMonthDays = prevMonth.getDate();
                    for (var i = daysBefore - 1; i >= 0; i--) {
                        const day = prevMonthDays - i;
                        days.push({
                            "day": day,
                            "month": month - 1,
                            "year": month === 0 ? year - 1 : year,
                            "today": false,
                            "currentMonth": false
                        });
                    }
                    // Current month days
                    for (var day = 1; day <= daysInMonth; day++) {
                        const date = new Date(year, month, day);
                        const isToday = date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate();
                        days.push({
                            "day": day,
                            "month": month,
                            "year": year,
                            "today": isToday,
                            "currentMonth": true
                        });
                    }
                    // Next month days
                    for (var i = 1; i <= daysAfter; i++) {
                        days.push({
                            "day": i,
                            "month": month + 1,
                            "year": month === 11 ? year + 1 : year,
                            "today": false,
                            "currentMonth": false
                        });
                    }
                    return days;
                }

                Layout.fillWidth: true
                columns: 7
                columnSpacing: Style.marginXXS
                rowSpacing: Style.marginXXS

                Repeater {
                    model: grid.daysModel

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Style.baseWidgetSize * 0.9

                        Rectangle {
                            width: Style.baseWidgetSize * 0.9
                            height: Style.baseWidgetSize * 0.9
                            anchors.centerIn: parent
                            radius: Style.radiusM
                            color: modelData.today ? Colors.mPrimary : "transparent"

                            UText {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: {
                                    if (modelData.today)
                                        return Colors.mOnPrimary;

                                    if (modelData.currentMonth)
                                        return Colors.mOnSurface;

                                    return Colors.mOnSurfaceVariant;
                                }
                                opacity: modelData.currentMonth ? 1 : 0.4
                                pointSize: Style.fontSizeM
                                font.weight: modelData.today ? Style.fontWeightBold : Style.fontWeightMedium
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

}
