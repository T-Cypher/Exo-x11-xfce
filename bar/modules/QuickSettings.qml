// Bar module: quick settings button (opens the quick centre).
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    selected: Surfaces.quickCenterOpen
    onClicked: Surfaces.toggle("quickcenter")

    M3Icon {
        name: tile.selected ? "close" : "tune"
        iconSize: Theme.moduleIconSize(Config.bar.density) + 3
        iconColor: tile.selected ? Theme.colors.onSecondaryContainer : Theme.colors.onSurface
    }
}
