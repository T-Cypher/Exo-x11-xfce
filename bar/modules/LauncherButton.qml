// Bar module: application launcher button (Exo's launcher toggle).
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    selected: Surfaces.launcherOpen
    onClicked: Surfaces.toggle("launcher")

    M3Icon {
        name: "apps"
        iconSize: Theme.moduleIconSize(Config.bar.density) + 3
        iconColor: tile.selected ? Theme.colors.onSecondaryContainer : Theme.colors.primary
    }
}
