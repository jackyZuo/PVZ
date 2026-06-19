@tool
class_name TowerDefenseItem extends TowerDefenseCharacter

@export var canCheck: bool = false
@export var canCheckTarget: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    instance.hitpointsEmpty.connect(Destroy)
    add_to_group("Item", true)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
