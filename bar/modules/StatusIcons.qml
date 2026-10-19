// Bar module: volume, network, bluetooth and battery at a glance.
//
// Clicking the group opens the quick centre; each icon also reacts on its own
// (volume mutes, scrolling changes it, right click toggles radios).
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null

    readonly property var wifiDevice: {
        const list = Networking.devices.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wifi)
                return list[i];
        }
        return null;
    }

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter

    onClicked: Surfaces.toggle("quickcenter")
    onScrolled: delta => {
        if (delta > 0)
            Osd.volumeUp();
        else
            Osd.volumeDown();
    }

    Row {
        spacing: 6

        // ------------------------------------------------------------- volume
        M3Icon {
            name: tile.sinkAudio !== null && tile.sinkAudio.muted ? "volume_off" : (tile.sinkAudio !== null && tile.sinkAudio.volume > 0.5 ? "volume_up" : "volume_down")
            iconSize: Theme.moduleIconSize(Config.bar.density) + 2
            iconColor: Theme.colors.onSurface
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: Osd.volumeToggleMute()
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0)
                        Osd.volumeUp();
                    else
                        Osd.volumeDown();
                }
            }
        }

        // ------------------------------------------------------------ network
        M3Icon {
            visible: tile.wifiDevice !== null
            name: !Networking.wifiEnabled ? "wifi_off" : "wifi"
            iconSize: Theme.moduleIconSize(Config.bar.density) + 2
            iconColor: Networking.wifiEnabled && Networking.connectivity === NetworkConnectivity.Full ? Theme.colors.onSurface : Theme.colors.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        Networking.wifiEnabled = !Networking.wifiEnabled;
                    else
                        Surfaces.toggle("quickcenter");
                }
            }
        }

        // ---------------------------------------------------------- bluetooth
        M3Icon {
            visible: tile.bluetoothAdapter !== null
            name: tile.bluetoothAdapter !== null && tile.bluetoothAdapter.enabled ? (tile.bluetoothAdapter.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
            iconSize: Theme.moduleIconSize(Config.bar.density) + 2
            iconColor: tile.bluetoothAdapter !== null && tile.bluetoothAdapter.enabled ? Theme.colors.onSurface : Theme.colors.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && tile.bluetoothAdapter !== null)
                        tile.bluetoothAdapter.enabled = !tile.bluetoothAdapter.enabled;
                    else
                        Surfaces.toggle("quickcenter");
                }
            }
        }

        // ------------------------------------------------------------ battery
        M3Icon {
            visible: Config.misc.showBattery && UPower.displayDevice !== null && UPower.displayDevice.ready
            name: {
                const device = UPower.displayDevice;
                if (device === null)
                    return "battery_unknown";
                if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
                    return "battery_charging_full";
                const level = device.percentage;
                if (level >= 95)
                    return "battery_full";
                if (level >= 80)
                    return "battery_6_bar";
                if (level >= 60)
                    return "battery_5_bar";
                if (level >= 45)
                    return "battery_4_bar";
                if (level >= 30)
                    return "battery_3_bar";
                if (level >= 15)
                    return "battery_2_bar";
                if (level >= 8)
                    return "battery_1_bar";
                return "battery_alert";
            }
            iconSize: Theme.moduleIconSize(Config.bar.density) + 3
            iconColor: UPower.displayDevice !== null && UPower.displayDevice.percentage < 15 && UPower.displayDevice.state !== UPowerDeviceState.Charging ? Theme.colors.error : Theme.colors.onSurface
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: Surfaces.toggle("quickcenter")
            }
        }

        M3Text {
            visible: Config.misc.showBattery && Config.bar.density === 0 && UPower.displayDevice !== null && UPower.displayDevice.ready
            text: UPower.displayDevice !== null ? Math.round(UPower.displayDevice.percentage) + "%" : ""
            role: "label"
            textColor: Theme.colors.onSurface
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
