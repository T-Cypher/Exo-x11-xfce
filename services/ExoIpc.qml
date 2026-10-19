// Exo for XFCE — IPC entry points.
//
// Every function here is reachable from the shell, which is how XFCE keyboard
// shortcuts drive the shell:
//
//   qs ipc call exo toggleLauncher
//   qs ipc call exo notify "Title" "Body"
import QtQuick
import Quickshell
import Quickshell.Io

IpcHandler {
    target: "exo"

    function toggleLauncher(): void {
        Surfaces.toggle("launcher");
    }

    function openLauncher(): void {
        Surfaces.open("launcher");
    }

    function toggleQuickCenter(): void {
        Surfaces.toggle("quickcenter");
    }

    function openQuickCenter(): void {
        Surfaces.open("quickcenter");
    }

    function togglePowerMenu(): void {
        Surfaces.toggle("powermenu");
    }

    function openSettings(): void {
        Surfaces.openSettings(0);
    }

    function closeOverlay(): void {
        Surfaces.close();
    }

    function toggleDnd(): void {
        Surfaces.dnd = !Surfaces.dnd;
    }

    function volumeUp(step: real): void {
        Osd.volumeUp(step > 0 ? step : 0.05);
    }

    function volumeDown(step: real): void {
        Osd.volumeDown(step > 0 ? step : 0.05);
    }

    function toggleMute(): void {
        Osd.volumeToggleMute();
    }

    function brightnessUp(step: real): void {
        Osd.brightnessUp(step > 0 ? step : 0.05);
        Osd.show("brightness_medium", Osd.brightnessPercent());
    }

    function brightnessDown(step: real): void {
        Osd.brightnessDown(step > 0 ? step : 0.05);
        Osd.show("brightness_medium", Osd.brightnessPercent());
    }

    function switchWorkspace(index: int): void {
        X11.switchDesktop(index);
    }

    function focusWindow(name: string): void {
        Quickshell.execDetached(["sh", "-c", "wmctrl -a " + name + " 2>/dev/null || wmctrl -x -a " + name + " 2>/dev/null || true"]);
    }

    function notify(title: string, body: string): void {
        Quickshell.execDetached(["notify-send", title, body]);
    }

    // Show the OSD manually, e.g. to test it: `qs -c exo ipc call exo osdTest 0.6`.
    function osdTest(value: real): void {
        Osd.ready = true;
        Osd.show("brightness_medium", value > 0 ? value : 0.6);
    }

    function reload(): void {
        Quickshell.reload(false);
    }

    function version(): string {
        return "exo-xfce 1.0 (quickshell 0.3.x, X11)";
    }

    // Diagnostics for troubleshooting: `qs -c exo ipc call exo debugNotifs`.
    function debugNotifs(): string {
        let out = "popups=" + Notifs.popups.length + " tracked=" + Notifs.tracked.length;
        for (let i = 0; i < Notifs.popups.length; i++) {
            const p = Notifs.popups[i];
            out += " | [" + i + "] " + (p === null ? "NULL" : (typeof p + " " + p.summary + " / " + p.appName));
        }
        return out;
    }

    // Diagnostics for troubleshooting: `qs -c exo ipc call exo debugState`.
    function debugState(): string {
        const win = X11.activeWindow;
        return "overlay=" + (Surfaces.overlay === "" ? "none" : Surfaces.overlay) + " desktops=" + X11.desktopCount + " activeDesktop=" + X11.activeDesktop + " windows=" + X11.windows.length + " activeWindow=" + (win !== null ? win.class + " / " + win.title : "none") + " fullscreen=" + X11.fullscreenWindow + " helper=" + X11.helperBuilt + " brightness=" + (Osd.brightnessAvailable ? Osd.brightnessDeviceName : "none");
    }
}
