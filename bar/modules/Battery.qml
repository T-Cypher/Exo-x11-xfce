// Bar module: battery (UPower), shown only on machines that have one.
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    readonly property var device: {
        if (Config.misc.batteryDevice.length > 0) {
            const list = UPower.devices.values;
            for (let i = 0; i < list.length; i++) {
                if (list[i].nativePath.indexOf(Config.misc.batteryDevice) >= 0)
                    return list[i];
            }
        }
        return UPower.displayDevice;
    }

    visible: Config.misc.showBattery && tile.device !== null && tile.device.ready && tile.device.isPresent
    hoverSurface: true
    onClicked: Surfaces.toggle("quickcenter")

    Row {
        spacing: 5

        M3Icon {
            name: {
                const device = tile.device;
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
            iconColor: tile.device !== null && tile.device.percentage < 15 && tile.device.state === UPowerDeviceState.Discharging ? Theme.colors.error : Theme.colors.onSurface
            anchors.verticalCenter: parent.verticalCenter
        }

        M3Text {
            visible: Config.bar.density <= 1
            text: tile.device !== null ? Math.round(tile.device.percentage) + "%" : ""
            role: "label"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
