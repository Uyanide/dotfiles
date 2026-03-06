import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Components
import qs.Constants
import qs.Services
import qs.Utils

Rectangle {
    id: root

    property real calculatedHeight: headerBox.implicitHeight + scrollView.implicitHeight + Style.marginL * 2 + Style.marginM
    property real contentPreferredHeight: Math.min(root.height, Math.ceil(calculatedHeight))
    property real layoutWidth: Math.max(1, root.width - Style.marginL * 2)

    color: "transparent"

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: Style.marginM

        // Header
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
                    Layout.fillWidth: true

                    UIcon {
                        iconName: "notes"
                        iconSize: Style.fontSizeXXL
                        color: Colors.mPrimary
                    }

                    UText {
                        text: "Notes" + " (" + NotesService.notesModel.count + ")"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Colors.mOnSurface
                        Layout.fillWidth: true
                    }

                    UIconButton {
                        iconName: "plus"
                        baseSize: Style.baseWidgetSize * 0.8
                        colorFg: Colors.mGreen
                        onClicked: NotesService.createNote()
                    }

                }

            }

        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NScrollView {
                id: scrollView

                anchors.fill: parent
                implicitHeight: notesColumn.implicitHeight

                ColumnLayout {
                    id: notesColumn

                    width: scrollView.width
                    spacing: Style.marginM

                    Repeater {
                        model: NotesService.notesModel

                        delegate: UBox {
                            property color accentColor: Colors.cavaList[model.colorIdx % Colors.cavaList.length]

                            width: notesColumn.width
                            implicitHeight: noteLayout.implicitHeight + Style.marginM * 2

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Style.marginS
                                color: parent.accentColor
                                radius: Style.radiusS
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: NotesService.openNote(model.noteId)
                            }

                            FileView {
                                id: fileView

                                path: NotesService.notesDir + "/" + model.noteId + ".txt"
                                watchChanges: true
                                onFileChanged: reload()
                            }

                            RowLayout {
                                id: noteLayout

                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                anchors.leftMargin: Style.marginM + Style.marginS

                                UText {
                                    Layout.fillWidth: true
                                    text: {
                                        var t = fileView.text();
                                        if (!t)
                                            return "(empty note)";

                                        return t.trim().split('\n').slice(0, 5).join('\n');
                                    }
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 5
                                }

                                UIconButton {
                                    iconName: "trash"
                                    baseSize: Style.baseWidgetSize * 0.8
                                    colorFg: Colors.mError
                                    onClicked: NotesService.deleteNote(model.noteId)
                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
