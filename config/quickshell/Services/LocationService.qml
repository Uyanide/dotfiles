import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

// Weather logic and caching with stable UI properties
Singleton {
    //console.log(JSON.stringify(weatherData))

    id: root

    property string locationName: SettingsService.location
    property string locationFile: CacheService.locationCacheFile
    property int weatherUpdateFrequency: 30 * 60 // 30 minutes expressed in seconds
    property bool isFetchingWeather: false
    readonly property alias data: adapter // Used to access via LocationService.data.xxx from outside, best to use "adapter" inside the service.
    // Stable UI properties - only updated when location is fully resolved
    property bool coordinatesReady: false
    property string stableLatitude: ""
    property string stableLongitude: ""
    property string stableName: ""
    // Helper property for UI components (outside JsonAdapter to avoid binding loops)
    readonly property string displayCoordinates: {
        if (!root.coordinatesReady || root.stableLatitude === "" || root.stableLongitude === "")
            return "";

        const lat = parseFloat(root.stableLatitude).toFixed(4);
        const lon = parseFloat(root.stableLongitude).toFixed(4);
        return `${lat}, ${lon}`;
    }

    // --------------------------------
    function init() {
        // does nothing but ensure the singleton is created
        // do not remove
        Logger.log("Location", "Service started");
    }

    // --------------------------------
    function resetWeather() {
        Logger.log("Location", "Resetting weather data");
        // Mark as changing to prevent UI updates
        root.coordinatesReady = false;
        // Reset stable properties
        root.stableLatitude = "";
        root.stableLongitude = "";
        root.stableName = "";
        // Reset core data
        adapter.latitude = "";
        adapter.longitude = "";
        adapter.name = "";
        adapter.weatherLastFetch = 0;
        adapter.weather = null;
        // Try to fetch immediately
        updateWeather();
    }

    // --------------------------------
    function updateWeather() {
        if (isFetchingWeather) {
            Logger.warn("Location", "Weather is still fetching");
            return ;
        }
        if ((adapter.weatherLastFetch === "") || (adapter.weather === null) || (adapter.latitude === "") || (adapter.longitude === "") || (adapter.name !== root.locationName) || (Time.timestamp >= adapter.weatherLastFetch + weatherUpdateFrequency))
            getFreshWeather();

    }

    // --------------------------------
    function getFreshWeather() {
        isFetchingWeather = true;
        // Check if location name has changed
        const locationChanged = data.name !== root.locationName;
        if (locationChanged) {
            root.coordinatesReady = false;
            Logger.log("Location", "Location changed from", adapter.name, "to", root.locationName);
        }
        if ((adapter.latitude === "") || (adapter.longitude === "") || locationChanged)
            _geocodeLocation(root.locationName, function(latitude, longitude, name, country) {
            Logger.log("Location", "Geocoded", root.locationName, "to:", latitude, "/", longitude);
            // Save location name
            adapter.name = root.locationName;
            // Save GPS coordinates
            adapter.latitude = latitude.toString();
            adapter.longitude = longitude.toString();
            root.stableName = `${name}, ${country}`;
            _fetchWeather(latitude, longitude, errorCallback);
        }, errorCallback);
        else
            _fetchWeather(adapter.latitude, adapter.longitude, errorCallback);
    }

    // --------------------------------
    function _geocodeLocation(locationName, callback, errorCallback) {
        Logger.log("Location", "Geocoding location name");
        var geoUrl = "https://assets.noctalia.dev/geocode.php?city=" + encodeURIComponent(locationName) + "&language=en&format=json";
        curl.fetch(geoUrl, function(success, data) {
            if (success) {
                try {
                    var geoData = JSON.parse(data);
                    if (geoData.lat != null)
                        callback(geoData.lat, geoData.lng, geoData.name, geoData.country);
                    else
                        errorCallback("Location", "could not resolve location name");
                } catch (e) {
                    errorCallback("Location", "Failed to parse geocoding data: " + e);
                }
            } else {
                errorCallback("Location", "Geocoding error");
            }
        });
    }

    // --------------------------------
    function _fetchWeather(latitude, longitude, errorCallback) {
        Logger.log("Location", "Fetching weather from api.open-meteo.com");
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current_weather=true&current=relativehumidity_2m,surface_pressure&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto";
        curl.fetch(url, function(success, fetchedData) {
            if (success) {
                try {
                    var weatherData = JSON.parse(fetchedData);
                    // Save core data
                    data.weather = weatherData;
                    data.weatherLastFetch = Time.timestamp;
                    // Update stable display values only when complete and successful
                    root.stableLatitude = data.latitude = weatherData.latitude.toString();
                    root.stableLongitude = data.longitude = weatherData.longitude.toString();
                    root.coordinatesReady = true;
                    isFetchingWeather = false;
                    Logger.log("Location", "Cached weather to disk - stable coordinates updated");
                } catch (e) {
                    errorCallback("Location", "Failed to parse weather data: " + e);
                }
            } else {
                errorCallback("Location", "Weather fetch error");
            }
        });
    }

    // --------------------------------
    function errorCallback(module, message) {
        Logger.error(module, message);
        isFetchingWeather = false;
    }

    // --------------------------------
    function weatherSymbolFromCode(code) {
        if (code === 0)
            return "weather-sun";

        if (code === 1 || code === 2)
            return "weather-cloud-sun";

        if (code === 3)
            return "weather-cloud";

        if (code >= 45 && code <= 48)
            return "weather-cloud-haze";

        if (code >= 51 && code <= 67)
            return "weather-cloud-rain";

        if (code >= 71 && code <= 77)
            return "weather-cloud-snow";

        if (code >= 71 && code <= 77)
            return "weather-cloud-snow";

        if (code >= 85 && code <= 86)
            return "weather-cloud-snow";

        if (code >= 95 && code <= 99)
            return "weather-cloud-lightning";

        return "weather-cloud";
    }

    function weatherColorFromCode(code) {
        // Clear sky - bright yellow
        if (code === 0)
            return Colors.yellow;

        // Mainly clear/Partly cloudy - soft peach/rosewater tones
        if (code === 1 || code === 2)
            return Colors.peach;

        // Overcast - neutral sky blue
        if (code === 3)
            return Colors.sky;

        // Fog - soft lavender/muted tone
        if (code >= 45 && code <= 48)
            return Colors.lavender;

        // Drizzle - light blue/sapphire
        if (code >= 51 && code <= 67)
            return Colors.sapphire;

        // Snow - cool teal
        if (code >= 71 && code <= 77)
            return Colors.teal;

        // Rain showers - deeper blue
        if (code >= 80 && code <= 82)
            return Colors.blue;

        // Snow showers - teal
        if (code >= 85 && code <= 86)
            return Colors.teal;

        // Thunderstorm - dramatic mauve/pink
        if (code >= 95 && code <= 99)
            return Colors.mauve;

        // Default - sky blue
        return Colors.sky;
    }

    // --------------------------------
    function weatherDescriptionFromCode(code) {
        if (code === 0)
            return "Clear sky";

        if (code === 1)
            return "Mainly clear";

        if (code === 2)
            return "Partly cloudy";

        if (code === 3)
            return "Overcast";

        if (code === 45 || code === 48)
            return "Fog";

        if (code >= 51 && code <= 67)
            return "Drizzle";

        if (code >= 71 && code <= 77)
            return "Snow";

        if (code >= 80 && code <= 82)
            return "Rain showers";

        if (code >= 95 && code <= 99)
            return "Thunderstorm";

        return "Unknown";
    }

    // --------------------------------
    function celsiusToFahrenheit(celsius) {
        return 32 + celsius * 1.8;
    }

    FileView {
        id: locationFileView

        path: locationFile
        printErrors: false
        onAdapterUpdated: saveTimer.start()
        onLoaded: {
            Logger.log("Location", "Loaded cached data");
            // Initialize stable properties on load
            if (adapter.latitude !== "" && adapter.longitude !== "" && adapter.weatherLastFetch > 0) {
                root.stableLatitude = adapter.latitude;
                root.stableLongitude = adapter.longitude;
                root.stableName = adapter.name;
                root.coordinatesReady = true;
                Logger.log("Location", "Coordinates ready");
            }
            updateWeather();
        }
        onLoadFailed: function(error) {
            updateWeather();
        }

        JsonAdapter {
            id: adapter

            // Core data properties
            property string latitude: ""
            property string longitude: ""
            property string name: ""
            property int weatherLastFetch: 0
            property var weather: null
        }

    }

    // Every 20s check if we need to fetch new weather
    Timer {
        id: updateTimer

        interval: 20 * 1000
        running: true
        repeat: true
        onTriggered: {
            updateWeather();
        }
    }

    Timer {
        id: saveTimer

        running: false
        interval: 1000
        onTriggered: locationFileView.writeAdapter()
    }

    NetworkFetch {
        id: curl
    }

}
