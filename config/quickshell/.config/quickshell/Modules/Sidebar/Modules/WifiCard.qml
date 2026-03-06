import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Constants
import qs.Components
import qs.Services
import qs.Utils

ColumnLayout {
    property string passwordSsid: ""
    property string passwordInput: ""
    property string expandedSsid: ""

    // Error message
    Rectangle {
        visible: NetworkService.lastError.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: errorRow.implicitHeight + (Style.marginS * 2)
        color: Qt.rgba(Colors.mError.r, Colors.mError.g, Colors.mError.b, 0.1)
        radius: Style.radiusS
        border.width: Math.max(1, Style.borderS)
        border.color: Colors.mError

        RowLayout {
            id: errorRow

            anchors.fill: parent
            anchors.margins: Style.marginS
            spacing: Style.marginS

            UIcon {
                iconName: "warning"
                iconSize: Style.fontSizeL
                color: Colors.mError
            }

            UText {
                text: NetworkService.lastError
                color: Colors.mError
                pointSize: Style.fontSizeS
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            UIconButton {
                iconName: "close"
                baseSize: Style.baseWidgetSize * 0.6
                onClicked: NetworkService.lastError = ""
            }

        }

    }

    // Main content area
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Colors.transparent

        // WiFi disabled state
        ColumnLayout {
            visible: !SettingsService.wifiEnabled
            anchors.fill: parent
            spacing: Style.marginS

            Item {
                Layout.fillHeight: true
            }

            UIcon {
                iconName: "wifi-off"
                iconSize: 64
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            UText {
                text: "Wi-Fi Disabled"
                pointSize: Style.fontSizeL
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            UText {
                text: "Please enable Wi-Fi to connect to a network."
                pointSize: Style.fontSizeS
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            Item {
                Layout.fillHeight: true
            }

        }

        // Scanning state
        ColumnLayout {
            visible: SettingsService.wifiEnabled && NetworkService.scanning && Object.keys(NetworkService.networks).length === 0
            anchors.fill: parent
            spacing: Style.marginL

            Item {
                Layout.fillHeight: true
            }

            UBusyIndicator {
                running: true
                color: Colors.mPrimary
                size: Style.baseWidgetSize
                Layout.alignment: Qt.AlignHCenter
            }

            UText {
                text: "Searching for networks..."
                pointSize: Style.fontSizeM
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            Item {
                Layout.fillHeight: true
            }

        }

        // Networks list container
        UScrollView {
            visible: SettingsService.wifiEnabled && (!NetworkService.scanning || Object.keys(NetworkService.networks).length > 0)
            anchors.fill: parent
            horizontalPolicy: ScrollBar.AlwaysOff
            verticalPolicy: ScrollBar.AsNeeded
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: Style.marginS

                // Network list
                Repeater {
                    model: {
                        if (!SettingsService.wifiEnabled)
                            return [];

                        const nets = Object.values(NetworkService.networks);
                        return nets.sort((a, b) => {
                            if (a.connected !== b.connected)
                                return a.connected ? -1 : 1;

                            return b.signal - a.signal;
                        });
                    }

                    UBox {
                        Layout.fillWidth: true
                        implicitHeight: netColumn.implicitHeight + (Style.marginS * 2)
                        compact: true

                        ColumnLayout {
                            id: netColumn

                            width: parent.width - (Style.marginS * 2)
                            x: Style.marginS
                            y: Style.marginS
                            spacing: Style.marginS

                            // Main row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginS

                                UIcon {
                                    iconName: NetworkService.signalIcon(modelData.signal)
                                    iconSize: Style.fontSizeXXL
                                    color: modelData.connected ? Colors.mPrimary : Colors.mOnSurface
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    UText {
                                        text: modelData.ssid
                                        pointSize: Style.fontSizeM
                                        font.weight: modelData.connected ? Style.fontWeightBold : Style.fontWeightMedium
                                        color: Colors.mOnSurface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: Style.marginXS

                                        UText {
                                            text: `${modelData.signal}%`
                                            pointSize: Style.fontSizeXXS
                                            color: Colors.mOnSurfaceVariant
                                        }

                                        UText {
                                            text: "•"
                                            pointSize: Style.fontSizeXXS
                                            color: Colors.mOnSurfaceVariant
                                        }

                                        UText {
                                            text: NetworkService.isSecured(modelData.security) ? modelData.security : "Open"
                                            pointSize: Style.fontSizeXXS
                                            color: Colors.mOnSurfaceVariant
                                        }

                                        Item {
                                            Layout.preferredWidth: Style.marginXXS
                                        }

                                        // Update the status badges area (around line 237)
                                        Rectangle {
                                            visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
                                            color: Colors.mPrimary
                                            radius: height * 0.5
                                            width: connectedText.implicitWidth + (Style.marginS * 2)
                                            height: connectedText.implicitHeight + (Style.marginXXS * 2)

                                            UText {
                                                id: connectedText

                                                anchors.centerIn: parent
                                                text: "Connected"
                                                pointSize: Style.fontSizeXXS
                                                color: Colors.mOnPrimary
                                            }

                                        }

                                        Rectangle {
                                            visible: NetworkService.disconnectingFrom === modelData.ssid
                                            color: Colors.mError
                                            radius: height * 0.5
                                            width: disconnectingText.implicitWidth + (Style.marginS * 2)
                                            height: disconnectingText.implicitHeight + (Style.marginXXS * 2)

                                            UText {
                                                id: disconnectingText

                                                anchors.centerIn: parent
                                                text: "disconnecting"
                                                pointSize: Style.fontSizeXXS
                                                color: Colors.mOnPrimary
                                            }

                                        }

                                        Rectangle {
                                            visible: NetworkService.forgettingNetwork === modelData.ssid
                                            color: Colors.mError
                                            radius: height * 0.5
                                            width: forgettingText.implicitWidth + (Style.marginS * 2)
                                            height: forgettingText.implicitHeight + (Style.marginXXS * 2)

                                            UText {
                                                id: forgettingText

                                                anchors.centerIn: parent
                                                text: "forgetting"
                                                pointSize: Style.fontSizeXXS
                                                color: Colors.mOnPrimary
                                            }

                                        }

                                        Rectangle {
                                            visible: modelData.cached && !modelData.connected && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
                                            color: Colors.transparent
                                            border.color: Colors.mOutline
                                            border.width: Math.max(1, Style.borderS)
                                            radius: height * 0.5
                                            width: savedText.implicitWidth + (Style.marginS * 2)
                                            height: savedText.implicitHeight + (Style.marginXXS * 2)

                                            UText {
                                                id: savedText

                                                anchors.centerIn: parent
                                                text: "saved"
                                                pointSize: Style.fontSizeXXS
                                                color: Colors.mOnSurfaceVariant
                                            }

                                        }

                                    }

                                }

                                // Action area
                                RowLayout {
                                    spacing: Style.marginS

                                    UBusyIndicator {
                                        visible: NetworkService.connectingTo === modelData.ssid || NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid
                                        running: visible
                                        color: Colors.mPrimary
                                        size: Style.baseWidgetSize * 0.5
                                    }

                                    UIconButton {
                                        visible: (modelData.existing || modelData.cached) && !modelData.connected && NetworkService.connectingTo !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
                                        iconName: "trash"
                                        baseSize: Style.baseWidgetSize * 0.8
                                        onClicked: expandedSsid = expandedSsid === modelData.ssid ? "" : modelData.ssid
                                    }

                                    UButton {
                                        visible: !modelData.connected && NetworkService.connectingTo !== modelData.ssid && passwordSsid !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid
                                        text: {
                                            if (modelData.existing || modelData.cached)
                                                return "Connect";

                                            if (!NetworkService.isSecured(modelData.security))
                                                return "Connect";

                                            return "Enter Password";
                                        }
                                        outlined: false
                                        fontSize: Style.fontSizeXS
                                        enabled: !NetworkService.connecting
                                        onClicked: {
                                            if (modelData.existing || modelData.cached || !NetworkService.isSecured(modelData.security)) {
                                                NetworkService.connect(modelData.ssid);
                                            } else {
                                                passwordSsid = modelData.ssid;
                                                passwordInput = "";
                                                expandedSsid = "";
                                            }
                                        }
                                    }

                                    UButton {
                                        visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
                                        text: "Disconnect"
                                        outlined: false
                                        fontSize: Style.fontSizeXS
                                        backgroundColor: Colors.mError
                                        onClicked: NetworkService.disconnect(modelData.ssid)
                                    }

                                }

                            }

                            // Password input
                            Rectangle {
                                visible: passwordSsid === modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid
                                Layout.fillWidth: true
                                height: passwordRow.implicitHeight + Style.marginS * 2
                                color: Colors.mSurfaceVariant
                                border.color: Colors.mOutline
                                border.width: Math.max(1, Style.borderS)
                                radius: Style.radiusS

                                RowLayout {
                                    id: passwordRow

                                    anchors.fill: parent
                                    anchors.margins: Style.marginS
                                    spacing: Style.marginS

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Style.radiusXS
                                        color: Colors.mSurface
                                        border.color: pwdInput.activeFocus ? Colors.mSecondary : Colors.mOutline
                                        border.width: Math.max(1, Style.borderS)

                                        TextInput {
                                            id: pwdInput

                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.margins: Style.marginS
                                            text: passwordInput
                                            font.family: Fonts.sans
                                            font.pointSize: Style.fontSizeS
                                            color: Colors.mOnSurface
                                            echoMode: TextInput.Password
                                            selectByMouse: true
                                            focus: visible
                                            passwordCharacter: "●"
                                            onTextChanged: passwordInput = text
                                            onVisibleChanged: {
                                                if (visible)
                                                    forceActiveFocus();

                                            }
                                            onAccepted: {
                                                if (text && !NetworkService.connecting) {
                                                    NetworkService.connect(passwordSsid, text);
                                                    passwordSsid = "";
                                                    passwordInput = "";
                                                }
                                            }

                                            UText {
                                                visible: parent.text.length === 0
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Enter Password"
                                                color: Colors.mOnSurfaceVariant
                                                pointSize: Style.fontSizeS
                                            }

                                        }

                                    }

                                    UButton {
                                        text: "Connect"
                                        fontSize: Style.fontSizeXXS
                                        enabled: passwordInput.length > 0 && !NetworkService.connecting
                                        outlined: false
                                        onClicked: {
                                            NetworkService.connect(passwordSsid, passwordInput);
                                            passwordSsid = "";
                                            passwordInput = "";
                                        }
                                    }

                                    UIconButton {
                                        iconName: "close"
                                        baseSize: Style.baseWidgetSize * 0.8
                                        onClicked: {
                                            passwordSsid = "";
                                            passwordInput = "";
                                        }
                                    }

                                }

                            }

                            // Forget network
                            Rectangle {
                                visible: expandedSsid === modelData.ssid && NetworkService.disconnectingFrom !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid
                                Layout.fillWidth: true
                                height: forgetRow.implicitHeight + Style.marginS * 2
                                color: Colors.mSurfaceVariant
                                radius: Style.radiusS
                                border.width: Math.max(1, Style.borderS)
                                border.color: Colors.mOutline

                                RowLayout {
                                    id: forgetRow

                                    anchors.fill: parent
                                    anchors.margins: Style.marginS
                                    spacing: Style.marginS

                                    RowLayout {
                                        UIcon {
                                            iconName: "trash"
                                            iconSize: Style.fontSizeL
                                            color: Colors.mError
                                        }

                                        UText {
                                            text: "Forget this network?"
                                            pointSize: Style.fontSizeS
                                            color: Colors.mError
                                            Layout.fillWidth: true
                                        }

                                    }

                                    UButton {
                                        id: forgetButton

                                        text: "Forget"
                                        fontSize: Style.fontSizeXXS
                                        backgroundColor: Colors.mError
                                        outlined: false
                                        onClicked: {
                                            NetworkService.forget(modelData.ssid);
                                            expandedSsid = "";
                                        }
                                    }

                                    UIconButton {
                                        iconName: "close"
                                        baseSize: Style.baseWidgetSize * 0.8
                                        onClicked: expandedSsid = ""
                                    }

                                }

                            }

                        }

                        // Smooth opacity animation
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Style.animationNormal
                            }

                        }

                    }

                }

            }

        }

        // Empty state when no networks
        ColumnLayout {
            visible: SettingsService.wifiEnabled && !NetworkService.scanning && Object.keys(NetworkService.networks).length === 0
            anchors.fill: parent
            spacing: Style.marginL

            Item {
                Layout.fillHeight: true
            }

            UIcon {
                iconName: "search"
                iconSize: 64
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            UText {
                text: "No networks found"
                pointSize: Style.fontSizeL
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            UButton {
                text: "Scan Again"
                icon: "refresh"
                Layout.alignment: Qt.AlignHCenter
                onClicked: NetworkService.scan()
            }

            Item {
                Layout.fillHeight: true
            }

        }

    }

}
