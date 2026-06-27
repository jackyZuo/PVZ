@tool
class_name TowerDefenseItem extends TowerDefenseCharacter

@export var canCheck: bool = false
@export var canCheckTarget: bool = false
var targetZombie: TowerDefenseCharacter = null

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
    if is_instance_valid(targetZombie):
        global_position = targetZombie.global_position

func _on_target_zombie_destroyed() -> void :
    targetZombie = null
    Destroy()
