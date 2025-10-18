import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Modules.Misc
import qs.Utils
pragma Singleton

Singleton {
    id: manager

    // Properties
    property var currentPlayer: null
    property real currentPosition: 0
    property bool isPlaying: currentPlayer ? currentPlayer.isPlaying : false
    property int selectedPlayerIndex: -1
    property string trackTitle: currentPlayer ? (currentPlayer.trackTitle || "Unknown Track") : ""
    property string trackArtist: currentPlayer ? (currentPlayer.trackArtist || "Unknown Artist") : ""
    property string trackAlbum: currentPlayer ? (currentPlayer.trackAlbum || "Unknown Album") : ""
    property string trackArtUrl: currentPlayer ? (currentPlayer.trackArtUrl || "") : ""
    property real trackLength: currentPlayer ? currentPlayer.length : 0
    property bool canPlay: currentPlayer ? currentPlayer.canPlay : false
    property bool canPause: currentPlayer ? currentPlayer.canPause : false
    property bool canGoNext: currentPlayer ? currentPlayer.canGoNext : false
    property bool canGoPrevious: currentPlayer ? currentPlayer.canGoPrevious : false
    property bool canSeek: currentPlayer ? currentPlayer.canSeek : false
    property bool hasPlayer: getAvailablePlayers().length > 0
    // Expose cava values
    property alias cavaValues: cava.values

    // Returns available MPRIS players
    function getAvailablePlayers() {
        if (!Mpris.players || !Mpris.players.values)
            return [];

        let allPlayers = Mpris.players.values;
        let controllablePlayers = [];
        for (let i = 0; i < allPlayers.length; i++) {
            let player = allPlayers[i];
            if (player && player.canControl)
                controllablePlayers.push(player);

        }
        return controllablePlayers;
    }

    // Returns active player or first available
    function findActivePlayer() {
        let availablePlayers = getAvailablePlayers();
        if (availablePlayers.length === 0)
            return null;

        // Get the first playing player
        for (let i = availablePlayers.length - 1; i >= 0; i--) {
            if (availablePlayers[i].isPlaying)
                return availablePlayers[i];

        }
        // Fallback to last player
        return availablePlayers[availablePlayers.length - 1];
    }

    // Updates currentPlayer and currentPosition
    function updateCurrentPlayer() {
        // Use selected player if index is valid
        if (selectedPlayerIndex >= 0) {
            let availablePlayers = getAvailablePlayers();
            if (selectedPlayerIndex < availablePlayers.length) {
                currentPlayer = availablePlayers[selectedPlayerIndex];
                currentPosition = currentPlayer.position;
                Logger.log("MusicManager", "Current player set by index:", currentPlayer ? currentPlayer.identity : "None");
                return ;
            } else {
                selectedPlayerIndex = -1; // Reset if index is out of range
            }
        }
        // Otherwise, find active player
        let newPlayer = findActivePlayer();
        if (newPlayer !== currentPlayer) {
            currentPlayer = newPlayer;
            currentPosition = currentPlayer ? currentPlayer.position : 0;
        }
        Logger.log("MusicManager", "Current player updated:", currentPlayer ? currentPlayer.identity : "None");
    }

    // Player control functions
    function playPause() {
        if (currentPlayer) {
            if (currentPlayer.isPlaying)
                currentPlayer.pause();
            else
                currentPlayer.play();
        }
    }

    function isAllPaused() {
        let availablePlayers = getAvailablePlayers();
        for (let i = 0; i < availablePlayers.length; i++) {
            if (availablePlayers[i].isPlaying)
                return false;

        }
        return true;
    }

    function play() {
        if (currentPlayer && currentPlayer.canPlay)
            currentPlayer.play();

    }

    function pause() {
        if (currentPlayer && currentPlayer.canPause)
            currentPlayer.pause();

    }

    function next() {
        if (currentPlayer && currentPlayer.canGoNext)
            currentPlayer.next();

    }

    function previous() {
        if (currentPlayer && currentPlayer.canGoPrevious)
            currentPlayer.previous();

    }

    function seek(position) {
        if (currentPlayer && currentPlayer.canSeek) {
            currentPlayer.position = position;
            currentPosition = position;
        }
    }

    function seekByRatio(ratio) {
        if (currentPlayer && currentPlayer.canSeek && currentPlayer.length > 0) {
            let seekPosition = ratio * currentPlayer.length;
            currentPlayer.position = seekPosition;
            currentPosition = seekPosition;
        }
    }

    // Initialize
    Item {
        Component.onCompleted: {
            updateCurrentPlayer();
        }
    }

    // Updates progress bar every second
    Timer {
        id: positionTimer

        interval: 1000
        running: currentPlayer && currentPlayer.isPlaying && currentPlayer.length > 0
        repeat: true
        onTriggered: {
            if (currentPlayer && currentPlayer.isPlaying)
                currentPosition = currentPlayer.position;

        }
    }

    // Reacts to player list changes
    Connections {
        function onValuesChanged() {
            updateCurrentPlayer();
        }

        target: Mpris.players
    }

    Cava {
        id: cava

        count: 44
    }

}
