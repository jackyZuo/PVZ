@tool
extends TowerDefensePlant

var crater: TowerDefenseCharacter

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    await get_tree().physics_frame
    if is_instance_valid(cell):
        crater = cell.FindSlotParent(self)

func Explode() -> void :
    if is_instance_valid(crater):
        crater.Destroy()
