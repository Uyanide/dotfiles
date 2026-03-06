pragma Singleton
import Qt.labs.folderlistmodel

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
import qs.Constants

Singleton {
  id: root

  // Component registration - only poll when something needs system stat data
  function registerComponent(componentId) {
    root._registered[componentId] = true;
    root._registered = Object.assign({}, root._registered);
    Logger.d("SystemStat", "Component registered:", componentId, "- total:", root._registeredCount);
  }

  function unregisterComponent(componentId) {
    delete root._registered[componentId];
    root._registered = Object.assign({}, root._registered);
    Logger.d("SystemStat", "Component unregistered:", componentId, "- total:", root._registeredCount);
  }

  property var _registered: ({})
  readonly property int _registeredCount: Object.keys(_registered).length
  readonly property bool _lockScreenActive: PanelService.lockScreen?.active ?? false
  readonly property bool shouldRun: _registeredCount > 0 && !_lockScreenActive

  // Polling intervals (hardcoded to sensible values per stat type)
  readonly property int cpuUsageIntervalMs: 1000
  readonly property int cpuFreqIntervalMs: 3000
  readonly property int memIntervalMs: 5000
  readonly property int networkIntervalMs: 3000
  readonly property int loadAvgIntervalMs: 10000

  // Public values
  property real cpuUsage: 0
  property real cpuTemp: 0
  property string cpuFreq: "0.0GHz"
  property real cpuFreqRatio: 0
  property real cpuGlobalMaxFreq: 3.5
  property real memGb: 0
  property real memPercent: 0
  property real memTotalGb: 0
  property real rxSpeed: 0
  property real txSpeed: 0
  property real zfsArcSizeKb: 0 // ZFS ARC cache size in KB
  property real zfsArcCminKb: 0 // ZFS ARC minimum (non-reclaimable) size in KB
  property real loadAvg1: 0
  property real loadAvg5: 0
  property real loadAvg15: 0
  property int nproc: 0 // Number of cpu cores

  // History arrays (1 minute of data, length computed from polling interval)
  // Pre-filled with zeros so the graph scrolls smoothly from the start
  readonly property int historyDurationMs: (1 * 60 * 1000) // 1 minute

  // Computed history lengths based on polling intervals
  readonly property int cpuHistoryLength: Math.ceil(historyDurationMs / cpuUsageIntervalMs)
  readonly property int memHistoryLength: Math.ceil(historyDurationMs / memIntervalMs)
  readonly property int networkHistoryLength: Math.ceil(historyDurationMs / networkIntervalMs)

  property var cpuHistory: new Array(cpuHistoryLength).fill(0)
  property var cpuTempHistory: new Array(cpuHistoryLength).fill(40)  // Reasonable default temp
  property var memHistory: new Array(memHistoryLength).fill(0)
  property var rxSpeedHistory: new Array(networkHistoryLength).fill(0)
  property var txSpeedHistory: new Array(networkHistoryLength).fill(0)

  // Historical min/max tracking (since shell started) for consistent graph scaling
  // Temperature defaults create a valid 30-80°C range that expands as real data comes in
  property real cpuTempHistoryMin: 30
  property real cpuTempHistoryMax: 80
  // Network uses autoscaling from current history window

  // History management - called from update functions, not change handlers
  // (change handlers don't fire when value stays the same)
  function pushCpuHistory() {
    let h = cpuHistory.slice();
    h.push(cpuUsage);
    if (h.length > cpuHistoryLength)
      h.shift();
    cpuHistory = h;
  }

  function pushCpuTempHistory() {
    if (cpuTemp > 0) {
      if (cpuTemp < cpuTempHistoryMin)
        cpuTempHistoryMin = cpuTemp;
      if (cpuTemp > cpuTempHistoryMax)
        cpuTempHistoryMax = cpuTemp;
    }
    let h = cpuTempHistory.slice();
    h.push(cpuTemp);
    if (h.length > cpuHistoryLength)
      h.shift();
    cpuTempHistory = h;
  }

  function pushMemHistory() {
    let h = memHistory.slice();
    h.push(memPercent);
    if (h.length > memHistoryLength)
      h.shift();
    memHistory = h;
  }

  function pushNetworkHistory() {
    let rxH = rxSpeedHistory.slice();
    rxH.push(rxSpeed);
    if (rxH.length > networkHistoryLength)
      rxH.shift();
    rxSpeedHistory = rxH;

    let txH = txSpeedHistory.slice();
    txH.push(txSpeed);
    if (txH.length > networkHistoryLength)
      txH.shift();
    txSpeedHistory = txH;
  }

  // Network max speed tracking (autoscales from current history window)
  // Minimum floor of 1 MB/s so graph doesn't fluctuate at low speeds
  readonly property real rxMaxSpeed: {
    const max = Math.max(...rxSpeedHistory);
    return Math.max(max, 1000000); // 1 MB/s floor
  }
  readonly property real txMaxSpeed: {
    const max = Math.max(...txSpeedHistory);
    return Math.max(max, 512000); // 512 KB/s floor
  }

  // Ready-to-use ratios based on current maximums (0..1 range)
  readonly property real rxRatio: rxMaxSpeed > 0 ? Math.min(1, rxSpeed / rxMaxSpeed) : 0
  readonly property real txRatio: txMaxSpeed > 0 ? Math.min(1, txSpeed / txMaxSpeed) : 0

  // Internal state for CPU calculation
  property var prevCpuStats: null

  // Internal state for network speed calculation
  // Previous Bytes need to be stored as 'real' as they represent the total of bytes transfered
  // since the computer started, so their value will easily overlfow a 32bit int.
  property real prevRxBytes: 0
  property real prevTxBytes: 0
  property real prevTime: 0

  // Cpu temperature is the most complex
  readonly property var supportedTempCpuSensorNames: ["coretemp", "k10temp", "zenpower"]
  property string cpuTempSensorName: ""
  property string cpuTempHwmonPath: ""
  // For Intel coretemp averaging of all cores/sensors
  property var intelTempValues: []
  property int intelTempFilesChecked: 0
  property int intelTempMaxFiles: 20 // Will test up to temp20_input

  // Thermal zone fallback (for ARM SoCs with SCMI sensors, etc.)
  // Matches thermal zone types containing "cpu" and picks the hottest big-core zone.
  readonly property var thermalZoneCpuPatterns: ["cpu-b", "cpu-m", "cpu"]
  property string cpuThermalZonePath: ""
  property var cpuThermalZonePaths: [] // All matching CPU zones for averaging

  // --------------------------------------------
  Component.onCompleted: {
    Logger.i("SystemStat", "Service started (polling deferred until a consumer registers).");

    // Kickoff the cpu name detection for temperature (one-time probes, not polling)
    cpuTempNameReader.checkNext();

    // Get nproc on startup (one-time)
    nprocProcess.running = true;
  }

  onShouldRunChanged: {
    if (shouldRun) {
      // Reset differential state so first readings after resume are clean
      root.prevCpuStats = null;
      root.prevTime = 0;

      // Trigger initial reads
      zfsArcStatsFile.reload();
      loadAvgFile.reload();
    }
  }

  // Reset differential state after suspend so the first reading is treated as fresh
  Connections {
    target: Time
    function onResumed() {
      Logger.i("SystemStat", "System resumed - resetting differential state");
      root.prevCpuStats = null;
      root.prevTime = 0;
    }
  }

  // --------------------------------------------
  // Timer for CPU usage and temperature
  Timer {
    id: cpuTimer
    interval: root.cpuUsageIntervalMs
    repeat: true
    running: root.shouldRun
    triggeredOnStart: true
    onTriggered: {
      cpuStatFile.reload();
      updateCpuTemperature();
    }
  }

  // Timer for CPU frequency (slower — /proc/cpuinfo is large and freq changes infrequently)
  Timer {
    id: cpuFreqTimer
    interval: root.cpuFreqIntervalMs
    repeat: true
    running: root.shouldRun
    triggeredOnStart: true
    onTriggered: cpuInfoFile.reload()
  }

  // Timer for load average
  Timer {
    id: loadAvgTimer
    interval: root.loadAvgIntervalMs
    repeat: true
    running: root.shouldRun
    triggeredOnStart: true
    onTriggered: loadAvgFile.reload()
  }

  // Timer for memory stats
  Timer {
    id: memoryTimer
    interval: root.memIntervalMs
    repeat: true
    running: root.shouldRun
    triggeredOnStart: true
    onTriggered: {
      memInfoFile.reload();
      zfsArcStatsFile.reload();
    }
  }

  // Timer for network speeds
  Timer {
    id: networkTimer
    interval: root.networkIntervalMs
    repeat: true
    running: root.shouldRun
    triggeredOnStart: true
    onTriggered: netDevFile.reload()
  }

  // --------------------------------------------
  // FileView components for reading system files
  FileView {
    id: memInfoFile
    path: "/proc/meminfo"
    onLoaded: parseMemoryInfo(text())
  }

  FileView {
    id: cpuStatFile
    path: "/proc/stat"
    onLoaded: calculateCpuUsage(text())
  }

  FileView {
    id: netDevFile
    path: "/proc/net/dev"
    onLoaded: calculateNetworkSpeed(text())
  }

  FileView {
    id: loadAvgFile
    path: "/proc/loadavg"
    onLoaded: parseLoadAverage(text())
  }

  // ZFS ARC stats file (only exists on ZFS systems)
  FileView {
    id: zfsArcStatsFile
    path: "/proc/spl/kstat/zfs/arcstats"
    printErrors: false
    onLoaded: parseZfsArcStats(text())
    onLoadFailed: {
      // File doesn't exist (non-ZFS system), set ARC values to 0
      root.zfsArcSizeKb = 0;
      root.zfsArcCminKb = 0;
    }
  }

  // Process to get number of processors
  Process {
    id: nprocProcess
    command: ["nproc"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.nproc = parseInt(text.trim());
      }
    }
  }

  // FileView to get avg cpu frequency (replaces subprocess spawn of `cat /proc/cpuinfo`)
  FileView {
    id: cpuInfoFile
    path: "/proc/cpuinfo"
    onLoaded: {
      let txt = text();
      let matches = txt.match(/cpu MHz\s+:\s+([0-9.]+)/g);
      if (matches && matches.length > 0) {
        let totalFreq = 0.0;
        for (let i = 0; i < matches.length; i++) {
          totalFreq += parseFloat(matches[i].split(":")[1]);
        }
        let avgFreq = (totalFreq / matches.length) / 1000.0;
        root.cpuFreq = avgFreq.toFixed(1) + "GHz";
        cpuMaxFreqFile.reload();
        if (avgFreq > root.cpuGlobalMaxFreq)
        root.cpuGlobalMaxFreq = avgFreq;
        if (root.cpuGlobalMaxFreq > 0) {
          root.cpuFreqRatio = Math.min(1.0, avgFreq / root.cpuGlobalMaxFreq);
        }
      }
    }
  }

  // FileView to get maximum CPU frequency limit (replaces subprocess spawn)
  // Reads cpu0's scaling_max_freq as representative value
  FileView {
    id: cpuMaxFreqFile
    path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
    printErrors: false
    onLoaded: {
      let maxKHz = parseInt(text().trim());
      if (!isNaN(maxKHz) && maxKHz > 0) {
        let newMaxFreq = maxKHz / 1000000.0;
        if (Math.abs(root.cpuGlobalMaxFreq - newMaxFreq) > 0.01) {
          root.cpuGlobalMaxFreq = newMaxFreq;
        }
      }
    }
  }

  // --------------------------------------------
  // CPU Temperature
  // It's more complex.
  // ----
  // #1 - Find a common cpu sensor name ie: "coretemp", "k10temp", "zenpower"
  FileView {
    id: cpuTempNameReader
    property int currentIndex: 0
    printErrors: false

    function checkNext() {
      if (currentIndex >= 16) {
        // No hwmon sensor found, try thermal_zone fallback (ARM SoCs, SCMI, etc.)
        thermalZoneScanner.startScan();
        return;
      }

      cpuTempNameReader.path = `/sys/class/hwmon/hwmon${currentIndex}/name`;
      cpuTempNameReader.reload();
    }

    onLoaded: {
      const name = text().trim();
      if (root.supportedTempCpuSensorNames.includes(name)) {
        root.cpuTempSensorName = name;
        root.cpuTempHwmonPath = `/sys/class/hwmon/hwmon${currentIndex}`;
        Logger.i("SystemStat", `Found ${root.cpuTempSensorName} CPU thermal sensor at ${root.cpuTempHwmonPath}`);
      } else {
        currentIndex++;
        Qt.callLater(() => {
                       // Qt.callLater is mandatory
                       checkNext();
                     });
      }
    }

    onLoadFailed: function (error) {
      currentIndex++;
      Qt.callLater(() => {
                     // Qt.callLater is mandatory
                     checkNext();
                   });
    }
  }

  // ----
  // #2 - Read sensor value
  FileView {
    id: cpuTempReader
    printErrors: false

    onLoaded: {
      const data = text().trim();
      if (root.cpuTempSensorName === "coretemp") {
        // For Intel, collect all temperature values
        const temp = parseInt(data) / 1000.0;
        root.intelTempValues.push(temp);
        Qt.callLater(() => {
                       // Qt.callLater is mandatory
                       checkNextIntelTemp();
                     });
      } else {
        // For AMD sensors (k10temp and zenpower), directly set the temperature
        root.cpuTemp = Math.round(parseInt(data) / 1000.0);
        root.pushCpuTempHistory();
      }
    }
    onLoadFailed: function (error) {
      Qt.callLater(() => {
                     // Qt.callLater is mandatory
                     checkNextIntelTemp();
                   });
    }
  }

  // --------------------------------------------
  // Thermal zone fallback for CPU temperature
  // Used on ARM SoCs (e.g., SCMI sensors) where hwmon doesn't expose
  // coretemp/k10temp/zenpower. Scans /sys/class/thermal/thermal_zoneN/type
  // for CPU zone names, then reads temp from all matching zones.
  //
  // CPU: reads all cpu-*-thermal zones and reports the hottest core.

  FileView {
    id: thermalZoneScanner
    property int currentIndex: 0
    property var cpuZones: []
    printErrors: false

    function startScan() {
      currentIndex = 0;
      cpuZones = [];
      checkNext();
    }

    function checkNext() {
      if (currentIndex >= 20) {
        finishScan();
        return;
      }
      thermalZoneScanner.path = `/sys/class/thermal/thermal_zone${currentIndex}/type`;
      thermalZoneScanner.reload();
    }

    onLoaded: {
      const name = text().trim();
      const zonePath = `/sys/class/thermal/thermal_zone${currentIndex}`;
      if (name.startsWith("cpu") && name.endsWith("thermal")) {
        cpuZones.push({
                        "type": name,
                        "path": zonePath + "/temp"
                      });
      }
      currentIndex++;
      Qt.callLater(() => {
                     checkNext();
                   });
    }

    onLoadFailed: function (error) {
      currentIndex++;
      Qt.callLater(() => {
                     checkNext();
                   });
    }

    function finishScan() {
      if (cpuZones.length > 0) {
        root.cpuTempSensorName = "thermal_zone";
        root.cpuThermalZonePaths = cpuZones.map(z => z.path);
        const types = cpuZones.map(z => z.type).join(", ");
        Logger.i("SystemStat", `Found ${cpuZones.length} CPU thermal zone(s): ${types}`);
      } else if (root.cpuTempHwmonPath === "") {
        Logger.w("SystemStat", "No supported temperature sensor found");
      }
    }
  }

  // Thermal zone reader for CPU: reads all zones, reports max (hottest core)
  FileView {
    id: cpuThermalZoneReader
    property int currentZoneIndex: 0
    property var collectedTemps: []
    printErrors: false

    onLoaded: {
      const temp = parseInt(text().trim()) / 1000.0;
      if (!isNaN(temp) && temp > 0)
      collectedTemps.push(temp);
      currentZoneIndex++;
      Qt.callLater(() => {
                     readNextCpuThermalZone();
                   });
    }

    onLoadFailed: function (error) {
      currentZoneIndex++;
      Qt.callLater(() => {
                     readNextCpuThermalZone();
                   });
    }
  }

  function readNextCpuThermalZone() {
    if (cpuThermalZoneReader.currentZoneIndex >= root.cpuThermalZonePaths.length) {
      if (cpuThermalZoneReader.collectedTemps.length > 0) {
        root.cpuTemp = Math.round(Math.max(...cpuThermalZoneReader.collectedTemps));
      } else {
        root.cpuTemp = 0;
      }
      root.pushCpuTempHistory();
      return;
    }
    cpuThermalZoneReader.path = root.cpuThermalZonePaths[cpuThermalZoneReader.currentZoneIndex];
    cpuThermalZoneReader.reload();
  }

  // --------------------------------------------
  // Parse ZFS ARC stats from /proc/spl/kstat/zfs/arcstats
  function parseZfsArcStats(text) {
    if (!text)
      return;
    const lines = text.split('\n');

    // The file format is: name type data
    // We need to find the lines with "size" and "c_min" and extract the values (third column)
    let foundSize = false;
    let foundCmin = false;

    for (const line of lines) {
      const parts = line.trim().split(/\s+/);
      if (parts.length >= 3) {
        if (parts[0] === 'size') {
          // The value is in bytes, convert to KB
          const arcSizeBytes = parseInt(parts[2]) || 0;
          root.zfsArcSizeKb = Math.floor(arcSizeBytes / 1024);
          foundSize = true;
        } else if (parts[0] === 'c_min') {
          // The value is in bytes, convert to KB
          const arcCminBytes = parseInt(parts[2]) || 0;
          root.zfsArcCminKb = Math.floor(arcCminBytes / 1024);
          foundCmin = true;
        }

        // If we found both, we can return early
        if (foundSize && foundCmin) {
          return;
        }
      }
    }

    // If fields not found, set to 0
    if (!foundSize) {
      root.zfsArcSizeKb = 0;
    }
    if (!foundCmin) {
      root.zfsArcCminKb = 0;
    }
  }

  // --------------------------------------------
  // Parse load average from /proc/loadavg
  function parseLoadAverage(text) {
    if (!text)
      return;
    const parts = text.trim().split(/\s+/);
    if (parts.length >= 3) {
      root.loadAvg1 = parseFloat(parts[0]);
      root.loadAvg5 = parseFloat(parts[1]);
      root.loadAvg15 = parseFloat(parts[2]);
    }
  }

  // --------------------------------------------
  // Parse memory info from /proc/meminfo
  function parseMemoryInfo(text) {
    if (!text)
      return;
    const lines = text.split('\n');
    let memTotal = 0;
    let memAvailable = 0;

    for (const line of lines) {
      if (line.startsWith('MemTotal:')) {
        memTotal = parseInt(line.split(/\s+/)[1]) || 0;
      } else if (line.startsWith('MemAvailable:')) {
        memAvailable = parseInt(line.split(/\s+/)[1]) || 0;
      }
    }

    if (memTotal > 0) {
      // Calculate usage, adjusting for ZFS ARC cache if present
      let usageKb = memTotal - memAvailable;
      if (root.zfsArcSizeKb > 0) {
        usageKb = Math.max(0, usageKb - root.zfsArcSizeKb + root.zfsArcCminKb);
      }
      root.memGb = (usageKb / 1048576).toFixed(1); // 1024*1024 = 1048576
      root.memPercent = Math.round((usageKb / memTotal) * 100);
      root.memTotalGb = (memTotal / 1048576).toFixed(1);
      root.pushMemHistory();
    }
  }

  // --------------------------------------------
  // Calculate CPU usage from /proc/stat
  function calculateCpuUsage(text) {
    if (!text)
      return;
    const lines = text.split('\n');
    const cpuLine = lines[0];

    // First line is total CPU
    if (!cpuLine.startsWith('cpu '))
      return;
    const parts = cpuLine.split(/\s+/);
    const stats = {
      "user": parseInt(parts[1]) || 0,
      "nice": parseInt(parts[2]) || 0,
      "system": parseInt(parts[3]) || 0,
      "idle": parseInt(parts[4]) || 0,
      "iowait": parseInt(parts[5]) || 0,
      "irq": parseInt(parts[6]) || 0,
      "softirq": parseInt(parts[7]) || 0,
      "steal": parseInt(parts[8]) || 0,
      "guest": parseInt(parts[9]) || 0,
      "guestNice": parseInt(parts[10]) || 0
    };
    const totalIdle = stats.idle + stats.iowait;
    const total = Object.values(stats).reduce((sum, val) => sum + val, 0);

    if (root.prevCpuStats) {
      const prevTotalIdle = root.prevCpuStats.idle + root.prevCpuStats.iowait;
      const prevTotal = Object.values(root.prevCpuStats).reduce((sum, val) => sum + val, 0);

      const diffTotal = total - prevTotal;
      const diffIdle = totalIdle - prevTotalIdle;

      if (diffTotal > 0) {
        root.cpuUsage = (((diffTotal - diffIdle) / diffTotal) * 100).toFixed(1);
      }
      root.pushCpuHistory();
    }

    root.prevCpuStats = stats;
  }

  // --------------------------------------------
  // Check whether a network interface is virtual/tunnel/bridge.
  // Only physical interfaces (eth*, en*, wl*, ww*) are kept so
  // that traffic routed through VPNs, Docker bridges, etc. is
  // not double-counted.
  readonly property var _virtualPrefixes: ["lo", "docker", "veth", "br-", "virbr", "vnet", "tun", "tap", "wg", "tailscale", "nordlynx", "proton", "mullvad", "flannel", "cni", "cali", "vxlan", "genev", "gre", "sit", "ip6tnl", "dummy", "ifb", "nlmon", "bond"]

  function isVirtualInterface(name) {
    for (let i = 0; i < _virtualPrefixes.length; ++i) {
      if (name.startsWith(_virtualPrefixes[i]))
        return true;
    }
    return false;
  }

  // --------------------------------------------
  // Calculate RX and TX speed from /proc/net/dev
  // Sums speeds of all physical interfaces
  function calculateNetworkSpeed(text) {
    if (!text) {
      return;
    }

    const currentTime = Date.now() / 1000;
    const lines = text.split('\n');

    let totalRx = 0;
    let totalTx = 0;

    for (var i = 2; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) {
        continue;
      }

      const colonIndex = line.indexOf(':');
      if (colonIndex === -1) {
        continue;
      }

      const iface = line.substring(0, colonIndex).trim();
      if (isVirtualInterface(iface)) {
        continue;
      }

      const statsLine = line.substring(colonIndex + 1).trim();
      const stats = statsLine.split(/\s+/);

      const rxBytes = parseInt(stats[0], 10) || 0;
      const txBytes = parseInt(stats[8], 10) || 0;

      totalRx += rxBytes;
      totalTx += txBytes;
    }

    // Compute only if we have a previous run to compare to.
    if (root.prevTime > 0) {
      const timeDiff = currentTime - root.prevTime;

      // Avoid division by zero if time hasn't passed.
      if (timeDiff > 0) {
        let rxDiff = totalRx - root.prevRxBytes;
        let txDiff = totalTx - root.prevTxBytes;

        // Handle counter resets (e.g., WiFi reconnect), which would cause a negative value.
        if (rxDiff < 0) {
          rxDiff = 0;
        }
        if (txDiff < 0) {
          txDiff = 0;
        }

        root.rxSpeed = Math.round(rxDiff / timeDiff); // Speed in Bytes/s
        root.txSpeed = Math.round(txDiff / timeDiff);
      }
    }

    root.prevRxBytes = totalRx;
    root.prevTxBytes = totalTx;
    root.prevTime = currentTime;

    // Update network history after speeds are computed
    root.pushNetworkHistory();
  }

  // --------------------------------------------
  // Helper function to format network speeds
  function formatSpeed(bytesPerSecond) {
    const units = ["KB", "MB", "GB"];
    let value = bytesPerSecond / 1000;
    let unitIndex = 0;

    while (value >= 1000 && unitIndex < units.length - 1) {
      value /= 1000;
      unitIndex++;
    }

    const unit = units[unitIndex];
    const shortUnit = unit[0];
    const numStr = value < 10 ? value.toFixed(1) : Math.round(value).toString();

    return (numStr + unit).length > 5 ? numStr + shortUnit : numStr + unit;
  }

  // Compact speed formatter for vertical bar display
  function formatCompactSpeed(bytesPerSecond) {
    if (!bytesPerSecond || bytesPerSecond <= 0)
      return "0";
    const units = ["", "K", "M", "G"];
    let value = bytesPerSecond;
    let unitIndex = 0;
    while (value >= 1000 && unitIndex < units.length - 1) {
      value = value / 1000.0;
      unitIndex++;
    }
    // Promote at ~100 of current unit (e.g., 100k -> ~0.1M shown as 0.1M or 0M if rounded)
    if (unitIndex < units.length - 1 && value >= 100) {
      value = value / 1000.0;
      unitIndex++;
    }
    const display = Math.round(value).toString();
    return display + units[unitIndex];
  }

  // Smart formatter for memory values (GB) - max 4 chars
  // Uses decimal for < 10GB, integer otherwise
  function formatGigabytes(memGb) {
    const value = parseFloat(memGb);
    if (isNaN(value))
      return "0G";

    if (value < 10)
      return value.toFixed(1) + "G"; // "0.0G" to "9.9G"
    return Math.round(value) + "G"; // "10G" to "999G"
  }

  // Formatting gigabytes with optional padding
  function formatGigabytesDisplay(memGb, maxGb = null) {
    const value = formatGigabytes(memGb === null ? 0 : memGb);
    if (maxGb !== null) {
      const padding = Math.max(4, formatGigabytes(maxGb).length);
      return value.padStart(padding, " ");
    }
    return value;
  }

  // Formatting percentage with optional padding
  function formatPercentageDisplay(value, padding = false) {
    return `${Math.round(value === null ? 0 : value)}%`.padStart(padding ? 4 : 0, " ");
  }

  // Formatting ram usage
  function formatRamDisplay({
                            percent = false,
                            padding = false
} = {}) {
    if (percent) {
      return formatPercentageDisplay(memPercent, padding);
    } else {
      const maxGb = padding ? memTotalGb : null;
      return formatGigabytesDisplay(memGb, maxGb);
    }
  }

  // --------------------------------------------
  // Function to start fetching and computing the cpu temperature
  function updateCpuTemperature() {
    // For AMD sensors (k10temp and zenpower), only use Tctl sensor
    // temp1_input corresponds to Tctl (Temperature Control) on these sensors
    if (root.cpuTempSensorName === "k10temp" || root.cpuTempSensorName === "zenpower") {
      cpuTempReader.path = `${root.cpuTempHwmonPath}/temp1_input`;
      cpuTempReader.reload();
    } // For Intel coretemp, start averaging all available sensors/cores
    else if (root.cpuTempSensorName === "coretemp") {
      root.intelTempValues = [];
      root.intelTempFilesChecked = 0;
      checkNextIntelTemp();
    } // For thermal_zone fallback (ARM SoCs, SCMI, etc.), read all CPU zones and take max
    else if (root.cpuTempSensorName === "thermal_zone") {
      cpuThermalZoneReader.currentZoneIndex = 0;
      cpuThermalZoneReader.collectedTemps = [];
      readNextCpuThermalZone();
    }
  }

  // --------------------------------------------
  // Function to check next Intel temperature sensor
  function checkNextIntelTemp() {
    if (root.intelTempFilesChecked >= root.intelTempMaxFiles) {
      // Calculate average of all found temperatures
      if (root.intelTempValues.length > 0) {
        let sum = 0;
        for (var i = 0; i < root.intelTempValues.length; i++) {
          sum += root.intelTempValues[i];
        }
        root.cpuTemp = Math.round(sum / root.intelTempValues.length);
        root.pushCpuTempHistory();
      } else {
        Logger.w("SystemStat", "No temperature sensors found for coretemp");
        root.cpuTemp = 0;
        root.pushCpuTempHistory();
      }
      return;
    }

    // Check next temperature file
    root.intelTempFilesChecked++;
    cpuTempReader.path = `${root.cpuTempHwmonPath}/temp${root.intelTempFilesChecked}_input`;
    cpuTempReader.reload();
  }
}
