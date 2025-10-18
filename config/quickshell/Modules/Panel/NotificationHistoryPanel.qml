import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.Constants
import qs.Noctalia
import qs.Services
import qs.Utils

// Notification History panel
NPanel {
    id: root

    preferredWidth: 380
    preferredHeight: 480

    panelContent: Rectangle {
        id: notificationRect

        color: Color.transparent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            // Header section
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NIcon {
                    icon: "bell"
                    pointSize: Style.fontSizeXXL
                    color: Color.mPrimary
                }

                NText {
                    text: "Notifications"
                    pointSize: Style.fontSizeL
                    font.weight: Style.fontWeightBold
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }

                NIconButton {
                    icon: SettingsService.notifications.doNotDisturb ? "bell-off" : "bell"
                    baseSize: Style.baseWidgetSize * 0.8
                    onClicked: SettingsService.notifications.doNotDisturb = !SettingsService.notifications.doNotDisturb
                    colorFg: SettingsService.notifications.doNotDisturb ? Colors.base : Colors.green
                    colorBg: SettingsService.notifications.doNotDisturb ? Colors.green : Color.transparent
                    colorFgHover: Colors.base
                    colorBgHover: Colors.green
                }

                NIconButton {
                    icon: "trash"
                    baseSize: Style.baseWidgetSize * 0.8
                    onClicked: {
                        NotificationService.clearHistory();
                        // Close panel as there is nothing more to see.
                        root.close();
                    }
                    colorFg: Colors.red
                    colorBg: Color.transparent
                    colorFgHover: Colors.base
                    colorBgHover: Colors.red
                }

                NIconButton {
                    icon: "close"
                    baseSize: Style.baseWidgetSize * 0.8
                    onClicked: root.close()
                    colorFg: Colors.blue
                    colorBg: Color.transparent
                    colorFgHover: Colors.base
                    colorBgHover: Colors.blue
                }

            }

            NDivider {
                Layout.fillWidth: true
            }

            // Empty state when no notifications
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                visible: NotificationService.historyList.count === 0
                spacing: Style.marginL

                Item {
                    Layout.fillHeight: true
                }

                NIcon {
                    icon: "bell-off"
                    pointSize: 64
                    color: Color.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }

                NText {
                    text: "No Notifications"
                    pointSize: Style.fontSizeL
                    color: Color.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }

                Item {
                    Layout.fillHeight: true
                }

            }

            // Notification list
            NListView {
                id: notificationList

                // Track which notification is expanded
                property string expandedId: ""

                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalPolicy: ScrollBar.AlwaysOff
                verticalPolicy: ScrollBar.AsNeeded
                model: NotificationService.historyList
                spacing: Style.marginM
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: NotificationService.historyList.count > 0

                delegate: NBox {
                    property string notificationId: model.id
                    property bool isExpanded: notificationList.expandedId === notificationId

                    width: notificationList.width
                    height: notificationLayout.implicitHeight + (Style.marginM * 2)

                    // Click to expand/collapse
                    MouseArea {
                        anchors.fill: parent
                        // Don't capture clicks on the delete button
                        anchors.rightMargin: 48
                        enabled: (summaryText.truncated || bodyText.truncated)
                        onClicked: {
                            if (notificationList.expandedId === notificationId)
                                notificationList.expandedId = "";
                            else
                                notificationList.expandedId = notificationId;
                        }
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }

                    RowLayout {
                        id: notificationLayout

                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM

                        ColumnLayout {
                            NImageCircled {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 20
                                imagePath: model.cachedImage || model.originalImage || ""
                                borderColor: Color.transparent
                                borderWidth: 0
                                fallbackIcon: "bell"
                                fallbackIconSize: 24
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                        }

                        // Notification content column
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Style.marginXS
                            Layout.rightMargin: -(Style.marginM + Style.baseWidgetSize * 0.6)

                            // Header row with app name and timestamp
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginS

                                // Urgency indicator
                                Rectangle {
                                    Layout.preferredWidth: 6
                                    Layout.preferredHeight: 6
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 3
                                    visible: model.urgency !== 1
                                    color: {
                                        if (model.urgency === 2)
                                            return Color.mError;
                                        else if (model.urgency === 0)
                                            return Color.mOnSurfaceVariant;
                                        else
                                            return Color.transparent;
                                    }
                                }

                                NText {
                                    text: model.appName || "Unknown App"
                                    pointSize: Style.fontSizeXS
                                    color: Color.mSecondary
                                    family: Fonts.sans
                                }

                                NText {
                                    text: Time.formatRelativeTime(model.timestamp)
                                    pointSize: Style.fontSizeXS
                                    color: Color.mSecondary
                                    family: Fonts.sans
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                            }

                            // Summary
                            NText {
                                id: summaryText

                                text: model.summary || "No Summary"
                                pointSize: Style.fontSizeM
                                font.weight: Font.Medium
                                color: Color.mOnSurface
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                maximumLineCount: isExpanded ? 999 : 2
                                family: Fonts.sans
                                elide: Text.ElideRight
                            }

                            // Body
                            NText {
                                id: bodyText

                                text: model.body || ""
                                pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                maximumLineCount: isExpanded ? 999 : 3
                                elide: Text.ElideRight
                                family: Fonts.sans
                                visible: text.length > 0
                            }

                            // Spacer for expand indicator
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: (!isExpanded && (summaryText.truncated || bodyText.truncated)) ? (Style.marginS) : 0
                            }

                            // Expand indicator
                            RowLayout {
                                Layout.fillWidth: true
                                visible: !isExpanded && (summaryText.truncated || bodyText.truncated)
                                spacing: Style.marginXS

                                Item {
                                    Layout.fillWidth: true
                                }

                                NText {
                                    text: "Click to expand"
                                    pointSize: Style.fontSizeXS
                                    color: Color.mPrimary
                                    family: Fonts.sans
                                    font.weight: Font.Medium
                                }

                                NIcon {
                                    icon: "chevron-down"
                                    pointSize: Style.fontSizeS
                                    color: Color.mPrimary
                                }

                            }

                        }

                        // Delete button
                        NIconButton {
                            icon: "trash"
                            baseSize: Style.baseWidgetSize * 0.7
                            Layout.alignment: Qt.AlignTop
                            onClicked: {
                                // Remove from history using the service API
                                NotificationService.removeFromHistory(notificationId);
                            }
                            colorFg: Colors.red
                            colorBg: Color.transparent
                            colorFgHover: Colors.base
                            colorBgHover: Colors.red
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.animationNormal
                            easing.type: Easing.InOutQuad
                        }

                    }

                    // Smooth color transition on hover
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
