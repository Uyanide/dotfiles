import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Components
import qs.Constants

Rectangle {
    id: root

    // Public properties
    property string text: ""
    property string icon: ""
    property string tooltipText
    property color backgroundColor: Colors.mPrimary
    property color textColor: Colors.mOnPrimary
    property color hoverColor: Colors.mHover
    property color textHoverColor: Colors.mOnHover
    property real fontSize: Style.fontSizeM
    property int fontWeight: Style.fontWeightSemiBold
    property real iconSize: Style.fontSizeL
    property bool outlined: false
    property int horizontalAlignment: Qt.AlignHCenter
    property real buttonRadius: Style.radiusS
    // Internal properties
    property bool hovered: false
    readonly property color contentColor: {
        if (!root.enabled)
            return Colors.mOnSurfaceVariant;

        if (root.hovered)
            return root.textHoverColor;

        if (root.outlined)
            return root.backgroundColor;

        return root.textColor;
    }

    // Signals
    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal entered()
    signal exited()

    // Dimensions
    implicitWidth: contentRow.implicitWidth + (fontSize * 2)
    implicitHeight: contentRow.implicitHeight + (fontSize)
    // Appearance
    radius: root.buttonRadius
    color: {
        if (!root.enabled)
            return outlined ? "transparent" : Qt.lighter(Colors.mSurfaceVariant, 1.2);

        if (root.hovered)
            return hoverColor;

        return root.outlined ? "transparent" : root.backgroundColor;
    }
    border.width: outlined ? Style.borderS : 0
    border.color: {
        if (!root.enabled)
            return Colors.mOutline;

        if (root.hovered)
            return hoverColor;

        return root.outlined ? root.backgroundColor : "transparent";
    }
    opacity: enabled ? 1 : 0.6

    // Content
    RowLayout {
        id: contentRow

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.horizontalAlignment === Qt.AlignLeft ? parent.left : undefined
        anchors.horizontalCenter: root.horizontalAlignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
        anchors.leftMargin: root.horizontalAlignment === Qt.AlignLeft ? Style.marginL : 0
        spacing: Style.marginXS

        // Icon (optional)
        UIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root.icon !== ""
            iconName: root.icon
            iconSize: root.iconSize
            color: contentColor
        }

        // Text
        UText {
            Layout.alignment: Qt.AlignVCenter
            visible: root.text !== ""
            text: root.text
            pointSize: root.fontSize
            font.weight: root.fontWeight
            color: contentColor
        }

    }

    // Mouse interaction
    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: {
            root.hovered = true;
            root.entered();
        }
        onExited: {
            root.hovered = false;
            root.exited();
        }
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                root.clicked();
            else if (mouse.button == Qt.RightButton)
                root.rightClicked();
            else if (mouse.button == Qt.MiddleButton)
                root.middleClicked();
        }
        onCanceled: {
            root.hovered = false;
        }
    }

}
