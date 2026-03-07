import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services
import qs.Utils

// Weather overview card (placeholder data)
UBox {
    id: root

    property int forecastDays: 6
    property bool showLocation: true
    property bool showEffects: true
    readonly property bool weatherReady: LocationService.data.weather !== null
    // Test mode: set to "clear_day", "clear_night", "rain", "snow", "cloud" or "fog"
    property string testEffects: ""
    // Weather condition detection (delegates to LocationService, with testEffects override)
    readonly property bool isRaining: testEffects === "rain" || (testEffects === "" && LocationService.isRaining)
    readonly property bool isSnowing: testEffects === "snow" || (testEffects === "" && LocationService.isSnowing)
    readonly property bool isCloudy: testEffects === "cloud" || (testEffects === "" && LocationService.isCloudy)
    readonly property bool isFoggy: testEffects === "fog" || (testEffects === "" && LocationService.isFoggy)
    readonly property bool isClearDay: testEffects === "clear_day" || (testEffects === "" && LocationService.isClearDay)
    readonly property bool isClearNight: testEffects === "clear_night" || (testEffects === "" && LocationService.isClearNight)

    implicitHeight: Math.max(100, content.implicitHeight + Style.marginXL * 2)

    // Weather effect layer (rain/snow)
    Loader {
        id: weatherEffectLoader

        anchors.fill: parent
        active: root.showEffects && (root.isRaining || root.isSnowing || root.isCloudy || root.isFoggy || root.isClearDay || root.isClearNight)

        sourceComponent: Item {
            // Animated time for shaders
            property real shaderTime: 0

            anchors.fill: parent

            ShaderEffect {
                id: weatherEffect

                property var source
                property real time: parent.shaderTime
                property real itemWidth: weatherEffect.width
                property real itemHeight: weatherEffect.height
                property color bgColor: root.color
                property real cornerRadius: root.isRaining ? 0 : (root.radius - root.border.width)
                property real alternative: root.isFoggy

                anchors.fill: parent
                // Rain matches content margins, everything else fills the box
                anchors.margins: root.isRaining ? Style.marginXL : root.border.width
                fragmentShader: {
                    let shaderName;
                    if (root.isSnowing)
                        shaderName = "weather_snow";
                    else if (root.isRaining)
                        shaderName = "weather_rain";
                    else if (root.isCloudy || root.isFoggy)
                        shaderName = "weather_cloud";
                    else if (root.isClearDay)
                        shaderName = "weather_sun";
                    else if (root.isClearNight)
                        shaderName = "weather_stars";
                    else
                        shaderName = "";
                    return Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/" + shaderName + ".frag.qsb");
                }

                source: ShaderEffectSource {
                    sourceItem: content
                    hideSource: root.isRaining // Only hide for rain (distortion), show for snow
                }

            }

            NumberAnimation on shaderTime {
                loops: Animation.Infinite
                from: 0
                to: 1000
                duration: 100000
            }

        }

    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Style.marginXL
        spacing: Style.marginM
        clip: true

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Item {
                Layout.preferredWidth: Style.marginXXS
            }

            RowLayout {
                spacing: Style.marginL
                Layout.fillWidth: true

                UIcon {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: weatherReady ? LocationService.weatherSymbolFromCode(LocationService.data.weather.current_weather.weathercode, LocationService.data.weather.current_weather.is_day) : "weather-cloud-off"
                    iconSize: Style.fontSizeXXXL * 1.75
                    color: Colors.mPrimary
                }

                ColumnLayout {
                    spacing: Style.marginXXS

                    UText {
                        text: {
                            // Ensure the name is not too long if one had to specify the country
                            const loc = SettingsService.location || "Unknown Location";
                            const chunks = loc.split(",");
                            return chunks[0];
                        }
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        visible: showLocation
                    }

                    RowLayout {
                        UText {
                            visible: weatherReady
                            text: {
                                if (!weatherReady)
                                    return "";

                                var temp = LocationService.data.weather.current_weather.temperature;
                                var suffix = "C";
                                temp = Math.round(temp);
                                return `${temp}°${suffix}`;
                            }
                            pointSize: showLocation ? Style.fontSizeXL : Style.fontSizeXL * 1.6
                            font.weight: Style.fontWeightBold
                        }

                        UText {
                            text: weatherReady ? `(${LocationService.data.weather.timezone_abbreviation})` : ""
                            pointSize: Style.fontSizeXS
                            color: Colors.mOnSurfaceVariant
                            visible: LocationService.data.weather && showLocation
                        }

                    }

                }

            }

        }

        UDivider {
            visible: weatherReady
            Layout.fillWidth: true
        }

        RowLayout {
            visible: weatherReady
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Style.marginM

            Repeater {
                model: weatherReady ? Math.min(root.forecastDays, LocationService.data.weather.daily.time.length) : 0

                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXS

                    Item {
                        Layout.fillWidth: true
                    }

                    UText {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        text: {
                            var weatherDate = new Date(LocationService.data.weather.daily.time[index].replace(/-/g, "/"));
                            // return I18n.locale.toString(weatherDate, "ddd");
                            return Qt.formatDate(weatherDate, "ddd");
                        }
                        color: Colors.mOnSurface
                    }

                    UIcon {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        iconName: LocationService.weatherSymbolFromCode(LocationService.data.weather.daily.weathercode[index])
                        iconSize: Style.fontSizeXXL * 1.6
                        color: Colors.mPrimary
                    }

                    UText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            var max = LocationService.data.weather.daily.temperature_2m_max[index];
                            var min = LocationService.data.weather.daily.temperature_2m_min[index];
                            max = Math.round(max);
                            min = Math.round(min);
                            return `${max}°/${min}°`;
                        }
                        pointSize: Style.fontSizeXS
                        color: Colors.mOnSurfaceVariant
                    }

                }

            }

        }

    }

}
