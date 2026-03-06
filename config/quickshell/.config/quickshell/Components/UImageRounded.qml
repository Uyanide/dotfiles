import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.Constants

Item {
    id: root

    property real radius: 0
    property string imagePath: ""
    property string fallbackIcon: ""
    property real fallbackIconSize: Style.fontSizeXXL
    property real borderWidth: 0
    property color borderColor: "transparent"
    property int imageFillMode: Image.PreserveAspectCrop
    readonly property bool showFallback: (fallbackIcon !== undefined && fallbackIcon !== "") && (imagePath === undefined || imagePath === "" || imageSource.status === Image.Error)
    readonly property int status: imageSource.status

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.borderColor

        Image {
            id: imageSource

            anchors.fill: parent
            anchors.margins: root.borderWidth
            visible: false
            source: root.imagePath
            mipmap: true
            smooth: true
            asynchronous: true
            antialiasing: true
            fillMode: root.imageFillMode
        }

        ShaderEffect {
            property variant source: imageSource
            property real itemWidth: width
            property real itemHeight: height
            property real sourceWidth: imageSource.sourceSize.width
            property real sourceHeight: imageSource.sourceSize.height
            property real cornerRadius: Math.max(0, root.radius - root.borderWidth)
            property real imageOpacity: 1
            property int fillMode: root.imageFillMode

            anchors.fill: parent
            anchors.margins: root.borderWidth
            visible: !root.showFallback
            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/rounded_image.frag.qsb")
            supportsAtlasTextures: false
            blending: true
        }

        UIcon {
            anchors.fill: parent
            anchors.margins: root.borderWidth
            visible: root.showFallback
            iconName: root.fallbackIcon
            iconSize: root.fallbackIconSize
        }

    }

}
