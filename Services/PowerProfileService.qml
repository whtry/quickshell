pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configuredOutput:
        Quickshell.env("CLAVIS_INTERNAL_OUTPUT") || ""
    readonly property string configuredPowerSaverMode:
        Quickshell.env("CLAVIS_POWER_SAVER_MODE") || ""
    readonly property string configuredNormalMode:
        Quickshell.env("CLAVIS_NORMAL_MODE") || ""

    property string profile: "balanced"
    property bool available: false
    property bool busy: false
    property string lastError: ""
    property int powerSaverRefreshHz: 0
    property int normalRefreshHz: 0

    function validProfile(value) {
        return value === "power-saver"
            || value === "balanced"
            || value === "performance";
    }

    function refresh() {
        if (!profileReader.running)
            profileReader.running = true;
    }

    function setProfile(value) {
        if (!root.validProfile(value) || root.busy)
            return;

        root.busy = true;
        root.lastError = "";
        profileWriter.command = ["powerprofilesctl", "set", value];
        profileWriter.running = true;
    }

    function applyRefreshRate() {
        if (!root.available || !root.validProfile(root.profile)
                || !PersonalizationConfig.isExtensionEnabled(
                    "powerProfileRefreshRate"))
            return;

        const hasConfiguredModes = root.configuredOutput.length > 0
            && root.configuredPowerSaverMode.length > 0
            && root.configuredNormalMode.length > 0;
        if (hasConfiguredModes) {
            root.powerSaverRefreshHz = root.refreshHzFromModeText(
                root.configuredPowerSaverMode);
            root.normalRefreshHz = root.refreshHzFromModeText(
                root.configuredNormalMode);
            refreshRateWriter.command = [
                "niri", "msg", "output", root.configuredOutput, "mode",
                root.profile === "power-saver"
                    ? root.configuredPowerSaverMode
                    : root.configuredNormalMode
            ];
            refreshRateWriter.running = true;
            return;
        }

        if (!outputReader.running)
            outputReader.running = true;
    }

    function modeText(mode) {
        return Number(mode.width) + "x" + Number(mode.height) + "@"
            + (Number(mode.refresh_rate) / 1000).toFixed(3);
    }

    function refreshHzFromModeText(mode) {
        const match = String(mode || "").match(/@([0-9]+(?:\.[0-9]+)?)/);
        return match ? Math.round(Number(match[1])) : 0;
    }

    function applyDetectedRefreshRate(outputs) {
        if (!outputs || typeof outputs !== "object")
            return;

        const names = Object.keys(outputs);
        if (names.length === 0)
            return;

        let outputName = root.configuredOutput;
        if (!outputName || !outputs[outputName]) {
            outputName = names.find(name =>
                /^(eDP|LVDS|DSI)-/i.test(name)) || names[0];
        }

        const output = outputs[outputName];
        const modes = output && Array.isArray(output.modes)
            ? output.modes : [];
        const currentIndex = Number(output && output.current_mode);
        const current = modes[currentIndex];
        if (!current)
            return;

        const matching = modes.filter(mode =>
            Number(mode.width) === Number(current.width)
            && Number(mode.height) === Number(current.height));
        if (matching.length === 0)
            return;

        const saverMode = matching.reduce((best, mode) =>
            Math.abs(Number(mode.refresh_rate) - 60000)
                < Math.abs(Number(best.refresh_rate) - 60000)
                ? mode : best, matching[0]);
        const normalMode = matching.reduce((best, mode) =>
            Number(mode.refresh_rate) > Number(best.refresh_rate)
                ? mode : best, matching[0]);
        root.powerSaverRefreshHz = Math.round(
            Number(saverMode.refresh_rate) / 1000);
        root.normalRefreshHz = Math.round(
            Number(normalMode.refresh_rate) / 1000);

        const desired = root.profile === "power-saver"
            ? saverMode : normalMode;

        if (Number(desired.refresh_rate) === Number(current.refresh_rate))
            return;

        refreshRateWriter.command = [
            "niri", "msg", "output", outputName, "mode",
            root.modeText(desired)
        ];
        refreshRateWriter.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: profileReader

        command: ["powerprofilesctl", "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = this.text.trim();
                if (!root.validProfile(value))
                    return;

                const changed = root.profile !== value;
                root.profile = value;
                root.available = true;
                root.lastError = "";
                if (changed || !refreshRateWriter.running)
                    root.applyRefreshRate();
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.available = false;
                root.lastError = qsTr("电源模式服务不可用");
            }
        }
    }

    Process {
        id: profileWriter

        onExited: exitCode => {
            root.busy = false;
            if (exitCode === 0)
                root.refresh();
            else
                root.lastError = qsTr("切换电源模式失败");
        }
    }

    Process {
        id: refreshRateWriter

        onExited: exitCode => {
            if (exitCode !== 0)
                root.lastError = qsTr("刷新率切换失败");
        }
    }

    Process {
        id: outputReader

        command: ["niri", "msg", "--json", "outputs"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.applyDetectedRefreshRate(JSON.parse(this.text));
                } catch (error) {
                    root.lastError = qsTr("无法读取显示器模式");
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                root.lastError = qsTr("无法读取显示器模式");
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
