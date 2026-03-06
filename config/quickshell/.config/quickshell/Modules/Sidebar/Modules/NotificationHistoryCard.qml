import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.Components
import qs.Constants
import qs.Services
import qs.Utils

// Notification History panel
Rectangle {
    // Check if below visible area
    // Stop at edges

    id: root

    // Calculate content height based on header + tabs (if visible) + content
    property real calculatedHeight: {
        if (NotificationService.historyList.count === 0)
            return headerBox.implicitHeight + scrollView.implicitHeight + Style.marginL * 2 + Style.marginM;

        return headerBox.implicitHeight + scrollView.implicitHeight + Style.marginL * 2 + Style.marginM;
    }
    property real contentPreferredHeight: Math.min(root.height, Math.ceil(calculatedHeight))
    property real layoutWidth: Math.max(1, root.width - Style.marginL * 2)
    // State (lazy-loaded with root)
    property var rangeCounts: [0, 0, 0, 0]
    property var lastKnownDate: null // Track the current date to detect day changes
    // UI state (lazy-loaded with root)
    // 0 = All, 1 = Today, 2 = Yesterday, 3 = Earlier
    property int currentRange: 1
    // start on Today by default
    property bool groupByDate: true
    // Keyboard navigation state
    property int focusIndex: -1
    property int actionIndex: -1 // For actions within a notification

    function parseActions(actions) {
        try {
            return JSON.parse(actions || "[]");
        } catch (e) {
            return [];
        }
    }

    function moveSelection(dir) {
        var m = NotificationService.historyList;
        if (!m || m.count === 0)
            return ;

        var newIndex = focusIndex;
        var found = false;
        var count = m.count;
        // If no selection yet, start from beginning (or end if up)
        if (focusIndex === -1) {
            if (dir > 0)
                newIndex = -1;
            else
                newIndex = count;
        }
        // Loop to find next visible item
        var loopCount = 0;
        while (loopCount < count) {
            newIndex += dir;
            // Bounds check
            if (newIndex < 0 || newIndex >= count)
                break;

            var item = m.get(newIndex);
            if (item && isInCurrentRange(item.timestamp)) {
                found = true;
                break;
            }
            loopCount++;
        }
        if (found) {
            focusIndex = newIndex;
            actionIndex = -1; // Reset action selection
            scrollToItem(focusIndex);
        }
    }

    function moveAction(dir) {
        if (focusIndex === -1)
            return ;

        var item = NotificationService.historyList.get(focusIndex);
        if (!item)
            return ;

        var actions = parseActions(item.actionsJson);
        if (actions.length === 0)
            return ;

        var newActionIndex = actionIndex + dir;
        // Clamp between -1 (body) and actions.length - 1
        if (newActionIndex < -1)
            newActionIndex = -1;

        if (newActionIndex >= actions.length)
            newActionIndex = actions.length - 1;

        actionIndex = newActionIndex;
    }

    function activateSelection() {
        if (focusIndex === -1)
            return ;

        var item = NotificationService.historyList.get(focusIndex);
        if (!item)
            return ;

        if (actionIndex >= 0) {
            var actions = parseActions(item.actionsJson);
            if (actionIndex < actions.length)
                NotificationService.invokeAction(item.id, actions[actionIndex].identifier);

        } else {
            var delegate = notificationColumn.children[focusIndex];
            if (!delegate)
                return ;

            if (!(delegate.canExpand || delegate.isExpanded))
                return ;

            if (scrollView.expandedId === item.id)
                scrollView.expandedId = "";
            else
                scrollView.expandedId = item.id;
        }
    }

    function removeSelection() {
        if (focusIndex === -1)
            return ;

        var item = NotificationService.historyList.get(focusIndex);
        if (!item)
            return ;

        NotificationService.removeFromHistory(item.id);
    }

    function scrollToItem(index) {
        // Find the delegate item
        if (index < 0 || index >= notificationColumn.children.length)
            return ;

        var item = notificationColumn.children[index];
        if (item && item.visible) {
            // Use the internal flickable from NScrollView for accurate scrolling
            var flickable = scrollView._internalFlickable;
            if (!flickable || !flickable.contentItem)
                return ;

            var pos = flickable.contentItem.mapFromItem(item, 0, 0);
            var itemY = pos.y;
            var itemHeight = item.height;
            var currentContentY = flickable.contentY;
            var viewHeight = flickable.height;
            // Check if above visible area
            if (itemY < currentContentY)
                flickable.contentY = Math.max(0, itemY - Style.marginM);
            else if (itemY + itemHeight > currentContentY + viewHeight)
                flickable.contentY = (itemY + itemHeight) - viewHeight + Style.marginM;
        }
    }

    function resetFocus() {
        focusIndex = -1;
        actionIndex = -1;
    }

    // Helper functions (lazy-loaded with root)
    function dateOnly(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate());
    }

    function getDateKey(d) {
        // Returns a string key for the date (YYYY-MM-DD) for comparison
        var date = dateOnly(d);
        return date.getFullYear() + "-" + date.getMonth() + "-" + date.getDate();
    }

    function rangeForTimestamp(ts) {
        var dt = new Date(ts);
        var today = dateOnly(new Date());
        var thatDay = dateOnly(dt);
        var diffMs = today - thatDay;
        var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
        if (diffDays === 0)
            return 0;

        if (diffDays === 1)
            return 1;

        return 2;
    }

    function recalcRangeCounts() {
        var m = NotificationService.historyList;
        if (!m || typeof m.count === "undefined" || m.count <= 0) {
            root.rangeCounts = [0, 0, 0, 0];
            return ;
        }
        var counts = [0, 0, 0, 0];
        counts[0] = m.count;
        for (var i = 0; i < m.count; ++i) {
            var item = m.get(i);
            if (!item || typeof item.timestamp === "undefined")
                continue;

            var r = rangeForTimestamp(item.timestamp);
            counts[r + 1] = counts[r + 1] + 1;
        }
        root.rangeCounts = counts;
    }

    function isInCurrentRange(ts) {
        if (currentRange === 0)
            return true;

        return rangeForTimestamp(ts) === (currentRange - 1);
    }

    function countForRange(range) {
        return rangeCounts[range] || 0;
    }

    function hasNotificationsInCurrentRange() {
        var m = NotificationService.historyList;
        if (!m || m.count === 0)
            return false;

        for (var i = 0; i < m.count; ++i) {
            var item = m.get(i);
            if (item && isInCurrentRange(item.timestamp))
                return true;

        }
        return false;
    }

    color: "transparent"
    onCurrentRangeChanged: resetFocus()
    Component.onCompleted: {
        NotificationService.updateLastSeenTs();
        recalcRangeCounts();
        // Initialize lastKnownDate
        lastKnownDate = getDateKey(new Date());
    }

    Connections {
        function onCountChanged() {
            root.recalcRangeCounts();
        }

        target: NotificationService.historyList
    }

    // Timer to check for day changes at midnight
    Timer {
        // Day has changed, recalculate counts

        id: dayChangeTimer

        interval: 60000 // Check every minute
        repeat: true
        running: true // Always runs when root exists (panel is open)
        onTriggered: {
            var currentDateKey = root.getDateKey(new Date());
            if (root.lastKnownDate !== null && root.lastKnownDate !== currentDateKey)
                root.recalcRangeCounts();

            root.lastKnownDate = currentDateKey;
        }
    }

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: Style.marginM

        // Header section
        UBox {
            id: headerBox

            Layout.fillWidth: true
            implicitHeight: header.implicitHeight + Style.marginM * 2

            ColumnLayout {
                id: header

                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                RowLayout {
                    id: headerRow

                    Layout.fillWidth: true

                    UIcon {
                        iconName: "bell"
                        iconSize: Style.fontSizeXXL
                        color: Colors.mPrimary
                    }

                    UText {
                        text: "Notifications" + " (" + root.countForRange(tabsBox.currentIndex) + ")"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Colors.mOnSurface
                        Layout.fillWidth: true
                    }

                    UIconButton {
                        iconName: NotificationService.doNotDisturb ? "bell-off" : "bell"
                        baseSize: Style.baseWidgetSize * 0.8
                        colorFg: Colors.mGreen
                        alwaysHover: NotificationService.doNotDisturb
                        onClicked: NotificationService.toggleDoNotDisturb()
                    }

                    UIconButton {
                        // Close panel as there is nothing more to see.

                        iconName: "trash"
                        baseSize: Style.baseWidgetSize * 0.8
                        colorFg: Colors.mError
                        onClicked: {
                            NotificationService.clearHistory();
                        }
                    }

                }

                // Time range tabs ([All] / [Today] / [Yesterday] / [Earlier])
                UTabBar {
                    id: tabsBox

                    Layout.fillWidth: true
                    visible: NotificationService.historyList.count > 0 && root.groupByDate
                    currentIndex: root.currentRange
                    tabHeight: Math.round(Style.baseWidgetSize * 0.8)
                    spacing: Style.marginXS
                    distributeEvenly: true

                    UTabButton {
                        tabIndex: 0
                        text: "All"
                        checked: tabsBox.currentIndex === 0
                        onClicked: root.currentRange = 0
                        pointSize: Style.fontSizeXS
                    }

                    UTabButton {
                        tabIndex: 1
                        text: "Today"
                        checked: tabsBox.currentIndex === 1
                        onClicked: root.currentRange = 1
                        pointSize: Style.fontSizeXS
                    }

                    UTabButton {
                        tabIndex: 2
                        text: "Yesterday"
                        checked: tabsBox.currentIndex === 2
                        onClicked: root.currentRange = 2
                        pointSize: Style.fontSizeXS
                    }

                    UTabButton {
                        tabIndex: 3
                        text: "Earlier"
                        checked: tabsBox.currentIndex === 3
                        onClicked: root.currentRange = 3
                        pointSize: Style.fontSizeXS
                    }

                }

            }

        }

        // Notification list container with gradient overlay
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NScrollView {
                id: scrollView

                // Track which notification is expanded
                property string expandedId: ""

                anchors.fill: parent
                horizontalPolicy: ScrollBar.AlwaysOff
                verticalPolicy: ScrollBar.AsNeeded
                reserveScrollbarSpace: false
                gradientColor: Colors.mSurface

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Style.marginM

                    // Empty state when no notifications
                    UBox {
                        visible: !root.hasNotificationsInCurrentRange()
                        Layout.fillWidth: true
                        Layout.preferredHeight: emptyState.implicitHeight + Style.marginM * 2

                        ColumnLayout {
                            id: emptyState

                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginM

                            Item {
                                Layout.fillHeight: true
                            }

                            UIcon {
                                iconName: "bell-off"
                                iconSize: (NotificationService.historyList.count === 0) ? 48 : Style.baseWidgetSize
                                color: Colors.mOnSurfaceVariant
                                Layout.alignment: Qt.AlignHCenter
                            }

                            UText {
                                text: "No notifications"
                                pointSize: (NotificationService.historyList.count === 0) ? Style.fontSizeL : Style.fontSizeM
                                color: Colors.mOnSurfaceVariant
                                Layout.alignment: Qt.AlignHCenter
                            }

                            UText {
                                visible: NotificationService.historyList.count === 0
                                text: "No notifications in this range"
                                pointSize: Style.fontSizeS
                                color: Colors.mOnSurfaceVariant
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                        }

                    }

                    // Notification list container
                    Item {
                        visible: root.hasNotificationsInCurrentRange()
                        Layout.fillWidth: true
                        Layout.preferredHeight: notificationColumn.implicitHeight

                        Column {
                            id: notificationColumn

                            anchors.fill: parent
                            spacing: Style.marginS

                            Repeater {
                                model: NotificationService.historyList

                                delegate: Item {
                                    id: notificationDelegate

                                    property int listIndex: index
                                    property string notificationId: model.id
                                    property string appName: model.appName || ""
                                    property bool isExpanded: scrollView.expandedId === notificationId
                                    property bool canExpand: summaryText.truncated || bodyText.truncated
                                    property real swipeOffset: 0
                                    property real pressGlobalX: 0
                                    property real pressGlobalY: 0
                                    property bool isSwiping: false
                                    property bool isRemoving: false
                                    property string pendingLink: ""
                                    readonly property real swipeStartThreshold: 16
                                    readonly property real swipeDismissThreshold: Math.max(110, width * 0.3)
                                    readonly property int removeAnimationDuration: Style.animationNormal
                                    readonly property int notificationTextFormat: notificationDelegate.isExpanded ? Text.MarkdownText : Text.StyledText
                                    readonly property real actionButtonSize: Style.baseWidgetSize * 0.8
                                    readonly property real buttonClusterWidth: notificationDelegate.actionButtonSize * 2 + Style.marginXS
                                    readonly property real iconSize: 40
                                    // Parse actions safely
                                    property var actionsList: parseActions(model.actionsJson)
                                    property bool isFocused: index === root.focusIndex

                                    function isSafeLink(link) {
                                        if (!link)
                                            return false;

                                        const lower = link.toLowerCase();
                                        const schemes = ["http://", "https://", "mailto:"];
                                        return schemes.some((scheme) => {
                                            return lower.startsWith(scheme);
                                        });
                                    }

                                    function linkAtPoint(x, y) {
                                        if (!notificationDelegate.isExpanded)
                                            return "";

                                        if (summaryText) {
                                            const summaryPoint = summaryText.mapFromItem(historyInteractionArea, x, y);
                                            if (summaryPoint.x >= 0 && summaryPoint.y >= 0 && summaryPoint.x <= summaryText.width && summaryPoint.y <= summaryText.height) {
                                                const summaryLink = summaryText.linkAt ? summaryText.linkAt(summaryPoint.x, summaryPoint.y) : "";
                                                if (isSafeLink(summaryLink))
                                                    return summaryLink;

                                            }
                                        }
                                        if (bodyText) {
                                            const bodyPoint = bodyText.mapFromItem(historyInteractionArea, x, y);
                                            if (bodyPoint.x >= 0 && bodyPoint.y >= 0 && bodyPoint.x <= bodyText.width && bodyPoint.y <= bodyText.height) {
                                                const bodyLink = bodyText.linkAt ? bodyText.linkAt(bodyPoint.x, bodyPoint.y) : "";
                                                if (isSafeLink(bodyLink))
                                                    return bodyLink;

                                            }
                                        }
                                        return "";
                                    }

                                    function updateCursorAt(x, y) {
                                        if (notificationDelegate.isExpanded && notificationDelegate.linkAtPoint(x, y))
                                            historyInteractionArea.cursorShape = Qt.PointingHandCursor;
                                        else
                                            historyInteractionArea.cursorShape = Qt.ArrowCursor;
                                    }

                                    function dismissBySwipe() {
                                        if (isRemoving)
                                            return ;

                                        isRemoving = true;
                                        isSwiping = false;
                                        swipeOffset = swipeOffset >= 0 ? width + Style.marginL : -width - Style.marginL;
                                        opacity = 0;
                                        removeTimer.restart();
                                    }

                                    width: parent.width
                                    visible: root.isInCurrentRange(model.timestamp)
                                    height: visible && !isRemoving ? contentColumn.height + Style.marginM * 2 : 0
                                    onVisibleChanged: {
                                        if (!visible) {
                                            notificationDelegate.isSwiping = false;
                                            notificationDelegate.swipeOffset = 0;
                                            notificationDelegate.opacity = 1;
                                            notificationDelegate.isRemoving = false;
                                            removeTimer.stop();
                                        }
                                    }
                                    Component.onDestruction: removeTimer.stop()

                                    Timer {
                                        id: removeTimer

                                        interval: notificationDelegate.removeAnimationDuration
                                        repeat: false
                                        onTriggered: NotificationService.removeFromHistory(notificationId)
                                    }

                                    Rectangle {
                                        // return "transparent";

                                        anchors.fill: parent
                                        radius: Style.radiusM
                                        color: Colors.mSurfaceVariant
                                        border.color: {
                                            if (notificationDelegate.isFocused)
                                                return Colors.mPrimary;

                                            return Qt.alpha(Colors.mOutline, Style.opacityHeavy);
                                        }
                                        border.width: notificationDelegate.isFocused ? Style.borderM : Style.borderS

                                        Behavior on color {
                                            enabled: true

                                            ColorAnimation {
                                                duration: Style.animationFast
                                            }

                                        }

                                    }

                                    // Click to expand/collapse
                                    MouseArea {
                                        id: historyInteractionArea

                                        anchors.fill: parent
                                        anchors.rightMargin: notificationDelegate.buttonClusterWidth + Style.marginM
                                        enabled: !notificationDelegate.isRemoving
                                        hoverEnabled: true
                                        cursorShape: Qt.ArrowCursor
                                        onPressed: (mouse) => {
                                            root.focusIndex = index;
                                            root.actionIndex = -1;
                                            if (notificationDelegate.isExpanded) {
                                                const link = notificationDelegate.linkAtPoint(mouse.x, mouse.y);
                                                if (link)
                                                    notificationDelegate.pendingLink = link;
                                                else
                                                    notificationDelegate.pendingLink = "";
                                            }
                                            if (mouse.button !== Qt.LeftButton)
                                                return ;

                                            const globalPoint = historyInteractionArea.mapToGlobal(mouse.x, mouse.y);
                                            notificationDelegate.pressGlobalX = globalPoint.x;
                                            notificationDelegate.pressGlobalY = globalPoint.y;
                                            notificationDelegate.isSwiping = false;
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (!(mouse.buttons & Qt.LeftButton) || notificationDelegate.isRemoving)
                                                return ;

                                            const globalPoint = historyInteractionArea.mapToGlobal(mouse.x, mouse.y);
                                            const deltaX = globalPoint.x - notificationDelegate.pressGlobalX;
                                            const deltaY = globalPoint.y - notificationDelegate.pressGlobalY;
                                            if (!notificationDelegate.isSwiping) {
                                                if (Math.abs(deltaX) < notificationDelegate.swipeStartThreshold)
                                                    return ;

                                                // Only start a swipe-dismiss when horizontal movement is dominant.
                                                if (Math.abs(deltaX) <= Math.abs(deltaY) * 1.15)
                                                    return ;

                                                notificationDelegate.isSwiping = true;
                                            }
                                            if (notificationDelegate.pendingLink && Math.abs(deltaX) >= notificationDelegate.swipeStartThreshold)
                                                notificationDelegate.pendingLink = "";

                                            notificationDelegate.swipeOffset = deltaX;
                                        }
                                        onReleased: (mouse) => {
                                            if (mouse.button !== Qt.LeftButton)
                                                return ;

                                            if (notificationDelegate.isSwiping) {
                                                if (Math.abs(notificationDelegate.swipeOffset) >= notificationDelegate.swipeDismissThreshold)
                                                    notificationDelegate.dismissBySwipe();
                                                else
                                                    notificationDelegate.swipeOffset = 0;
                                                notificationDelegate.isSwiping = false;
                                                notificationDelegate.pendingLink = "";
                                                return ;
                                            }
                                            if (notificationDelegate.pendingLink) {
                                                Qt.openUrlExternally(notificationDelegate.pendingLink);
                                                notificationDelegate.pendingLink = "";
                                                return ;
                                            }
                                            // Focus sender window (and invoke default action if available)
                                            var actions = notificationDelegate.actionsList;
                                            var hasDefault = actions.some(function(a) {
                                                return a.identifier === "default";
                                            });
                                            if (hasDefault) {
                                                NotificationService.focusSenderWindow(notificationDelegate.appName);
                                                NotificationService.invokeAction(notificationDelegate.notificationId, "default");
                                            } else {
                                                NotificationService.focusSenderWindow(notificationDelegate.appName);
                                            }
                                        }
                                        onCanceled: {
                                            notificationDelegate.isSwiping = false;
                                            notificationDelegate.swipeOffset = 0;
                                            notificationDelegate.pendingLink = "";
                                            historyInteractionArea.cursorShape = Qt.ArrowCursor;
                                        }
                                    }

                                    HoverHandler {
                                        target: historyInteractionArea
                                        onPointChanged: notificationDelegate.updateCursorAt(point.position.x, point.position.y)
                                        onActiveChanged: {
                                            if (!active)
                                                historyInteractionArea.cursorShape = Qt.ArrowCursor;

                                        }
                                    }

                                    Column {
                                        id: contentColumn

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: Style.marginM
                                        spacing: Style.marginM

                                        Row {
                                            width: parent.width
                                            spacing: Style.marginM

                                            // Icon
                                            UImageRounded {
                                                anchors.verticalCenter: notificationDelegate.isExpanded ? undefined : parent.verticalCenter
                                                width: notificationDelegate.iconSize
                                                height: notificationDelegate.iconSize
                                                radius: Math.min(Style.radiusL, width / 2)
                                                imagePath: model.cachedImage || model.originalImage || ""
                                                borderColor: "transparent"
                                                borderWidth: 0
                                                fallbackIcon: "bell"
                                                fallbackIconSize: 24
                                            }

                                            // Content
                                            Column {
                                                width: parent.width - notificationDelegate.iconSize - notificationDelegate.buttonClusterWidth - Style.marginM * 2
                                                spacing: Style.marginXS

                                                // Header row with app name and timestamp
                                                Row {
                                                    width: parent.width
                                                    spacing: Style.marginS

                                                    // Urgency indicator
                                                    Rectangle {
                                                        width: 6
                                                        height: 6
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        radius: 3
                                                        visible: model.urgency !== 1
                                                        color: {
                                                            if (model.urgency === 2)
                                                                return Colors.mError;
                                                            else if (model.urgency === 0)
                                                                return Colors.mOnSurfaceVariant;
                                                            else
                                                                return "transparent";
                                                        }
                                                    }

                                                    UText {
                                                        text: model.appName || "Unknown App"
                                                        pointSize: Style.fontSizeXS
                                                        font.weight: Style.fontWeightBold
                                                        color: Colors.mPrimary
                                                    }

                                                    UText {
                                                        textFormat: Text.PlainText
                                                        text: " " + Time.formatRelativeTime(model.timestamp)
                                                        pointSize: Style.fontSizeXXS
                                                        color: Colors.mOnSurfaceVariant
                                                        anchors.bottom: parent.bottom
                                                    }

                                                }

                                                // Summary
                                                UText {
                                                    id: summaryText

                                                    width: parent.width
                                                    text: notificationDelegate.isExpanded ? (model.summaryMarkdown || I18n.tr("common.no-summary")) : (model.summary || I18n.tr("common.no-summary"))
                                                    pointSize: Style.fontSizeM
                                                    color: Colors.mOnSurface
                                                    textFormat: notificationDelegate.notificationTextFormat
                                                    wrapMode: Text.Wrap
                                                    maximumLineCount: notificationDelegate.isExpanded ? 999 : 2
                                                    elide: Text.ElideRight
                                                }

                                                // Body
                                                UText {
                                                    id: bodyText

                                                    width: parent.width
                                                    text: notificationDelegate.isExpanded ? (model.bodyMarkdown || "") : (model.body || "")
                                                    pointSize: Style.fontSizeS
                                                    color: Colors.mOnSurfaceVariant
                                                    textFormat: notificationDelegate.notificationTextFormat
                                                    wrapMode: Text.Wrap
                                                    maximumLineCount: notificationDelegate.isExpanded ? 999 : 3
                                                    elide: Text.ElideRight
                                                    visible: text.length > 0
                                                }

                                                // Actions Flow
                                                Flow {
                                                    width: parent.width
                                                    spacing: Style.marginS
                                                    visible: notificationDelegate.actionsList.length > 0

                                                    Repeater {
                                                        model: notificationDelegate.actionsList

                                                        delegate: UButton {
                                                            readonly property bool actionNavActive: notificationDelegate.isFocused && root.actionIndex !== -1
                                                            readonly property bool isSelected: actionNavActive && root.actionIndex === index
                                                            // Capture modelData in a property to avoid reference errors
                                                            property var actionData: modelData

                                                            text: modelData.text
                                                            fontSize: Style.fontSizeS
                                                            backgroundColor: isSelected ? Colors.mSecondary : Colors.mPrimary
                                                            textColor: isSelected ? Colors.mOnSecondary : Colors.mOnPrimary
                                                            outlined: false
                                                            implicitHeight: 24
                                                            onHoveredChanged: {
                                                                if (hovered)
                                                                    root.focusIndex = notificationDelegate.listIndex;

                                                            }
                                                            onClicked: {
                                                                NotificationService.focusSenderWindow(notificationDelegate.appName);
                                                                NotificationService.invokeAction(notificationDelegate.notificationId, actionData.identifier);
                                                            }
                                                        }

                                                    }

                                                }

                                            }

                                            Item {
                                                width: notificationDelegate.buttonClusterWidth
                                                height: notificationDelegate.actionButtonSize

                                                Row {
                                                    anchors.right: parent.right
                                                    spacing: Style.marginXS

                                                    UIconButton {
                                                        id: expandButton

                                                        iconName: notificationDelegate.isExpanded ? "chevron-up" : "chevron-down"
                                                        baseSize: notificationDelegate.actionButtonSize
                                                        opacity: (notificationDelegate.canExpand || notificationDelegate.isExpanded) ? 1 : 0
                                                        enabled: notificationDelegate.canExpand || notificationDelegate.isExpanded
                                                        onClicked: {
                                                            notificationDelegate.pendingLink = "";
                                                            historyInteractionArea.cursorShape = Qt.ArrowCursor;
                                                            if (scrollView.expandedId === notificationId)
                                                                scrollView.expandedId = "";
                                                            else
                                                                scrollView.expandedId = notificationId;
                                                        }
                                                    }

                                                    // Delete button
                                                    UIconButton {
                                                        iconName: "trash"
                                                        baseSize: notificationDelegate.actionButtonSize
                                                        colorFg: Colors.mError
                                                        onClicked: {
                                                            NotificationService.removeFromHistory(notificationId);
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    transform: Translate {
                                        x: notificationDelegate.swipeOffset
                                    }

                                    Behavior on swipeOffset {
                                        enabled: !notificationDelegate.isSwiping

                                        NumberAnimation {
                                            duration: notificationDelegate.removeAnimationDuration
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                    Behavior on opacity {
                                        enabled: notificationDelegate.isRemoving

                                        NumberAnimation {
                                            duration: notificationDelegate.removeAnimationDuration
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                    Behavior on height {
                                        enabled: notificationDelegate.isRemoving

                                        NumberAnimation {
                                            duration: notificationDelegate.removeAnimationDuration
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                    Behavior on y {
                                        enabled: notificationDelegate.isRemoving

                                        NumberAnimation {
                                            duration: notificationDelegate.removeAnimationDuration
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
