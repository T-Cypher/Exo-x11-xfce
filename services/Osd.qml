// Exo for XFCE — on-screen display state (volume / brightness).
//
// Quickshell ships PipeWire support, so volume comes straight from the default
// sink.  Screen brightness has no portable service on X11, so it is read from
// and written to /sys/class/backlight (falling back to brightnessctl).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: osd

    property bool shown: false
    property string icon: "volume_up"
    property real value: 0
    property bool vertical: false

    // Suppress the OSD while the values are being read for the first time.
    property bool ready: false

    Timer {
        interval: 1000
        running: true
        onTriggered: osd.ready = true
    }

    Timer {
        id: hideTimer
        interval: Math.max(500, Config.osd.timeout)
        onTriggered: osd.shown = false
    }

    function show(iconName, newValue) {
        if (!Config.osd.enabled || !osd.ready)
            return;
        osd.icon = iconName;
        osd.value = Math.max(0, Math.min(1, newValue));
        osd.vertical = Config.osd.vertical;
        osd.shown = true;
        hideTimer.restart();
    }

    // ----------------------------------------------------------------- volume
    readonly property var sink: Pipewire.defaultAudioSink

    function volumeUp(step) {
        const node = sink;
        if (!node || !node.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = Math.min(1, node.audio.volume + (step ? step : 0.05));
    }

    function volumeDown(step) {
        const node = sink;
        if (!node || !node.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, node.audio.volume - (step ? step : 0.05));
    }

    function volumeToggleMute() {
        const node = sink;
        if (!node || !node.audio)
            return;
        node.audio.muted = !node.audio.muted;
    }

    // ------------------------------------------------------------- brightness
    property string brightnessDeviceName: Config.misc.brightnessDevice
    property bool brightnessAvailable: false
    property int brightnessMax: 100
    property int brightnessValue: 0

    onBrightnessDeviceNameChanged: probe.running = true
    property bool probed: false

    Component.onCompleted: probe.running = true

    Process {
        id: probe
        running: false
        command: {
            if (Config.misc.brightnessDevice.length > 0)
                return ["sh", "-c", "echo " + Config.misc.brightnessDevice];
            if (Pinned.rememberedBrightnessDevice.length > 0)
                return ["sh", "-c", "echo " + Pinned.rememberedBrightnessDevice];
            return ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -1"];
        }
        stdout: SplitParser {
            onRead: data => {
                const name = data.trim();
                osd.brightnessDeviceName = name;
                if (name.length > 0) {
                    Pinned.rememberBrightnessDevice(name);
                    brightnessFile.path = "/sys/class/backlight/" + name + "/brightness";
                    brightnessMaxFile.path = "/sys/class/backlight/" + name + "/max_brightness";
                } else {
                    osd.brightnessAvailable = false;
                }
            }
        }
    }

    FileView {
        id: brightnessFile
        path: ""
        onLoaded: {
            osd.brightnessValue = parseInt(text) || 0;
            osd.brightnessAvailable = osd.brightnessMax > 0;
        }
        onLoadFailed: osd.brightnessAvailable = false
    }

    FileView {
        id: brightnessMaxFile
        path: ""
        onLoaded: osd.brightnessMax = parseInt(text) || 100
    }

    function brightnessPercent() {
        if (!brightnessAvailable || brightnessMax <= 0)
            return 0;
        return brightnessValue / brightnessMax;
    }

    function setBrightness(percent) {
        if (!brightnessAvailable)
            return;
        const target = Math.max(1, Math.min(brightnessMax, Math.round(percent * brightnessMax)));
        brightnessValue = target;
        Quickshell.execDetached(["sh", "-c",
            "if printf '%s' " + target + " > /sys/class/backlight/" + brightnessDeviceName + "/brightness 2>/dev/null; then exit 0; fi; " +
            "command -v brightnessctl >/dev/null 2>&1 && brightnessctl -q set " + target + " >/dev/null 2>&1; " +
            "true"]);
    }

    function brightnessUp(step) {
        setBrightness(brightnessPercent() + (step ? step : 0.05));
    }

    function brightnessDown(step) {
        setBrightness(brightnessPercent() - (step ? step : 0.05));
    }
}
