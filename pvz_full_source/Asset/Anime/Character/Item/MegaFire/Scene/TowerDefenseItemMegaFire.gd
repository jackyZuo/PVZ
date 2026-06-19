@tool
extends TowerDefenseItem

const CHERRY_BOMB_EXPLOSION = preload("uid://cibtjjjomdxnh")

@export var allEventList: Array[TowerDefenseCharacterEventBase] = []

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.invincible = true
    hitBox.monitorable = false
    await get_tree().create_timer(15.0, false).timeout
    Destroy()

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale

    if Engine.get_physics_frames() % 2 == 0:
        TowerDefenseExplode.CreateExplode(global_position, Vector2(0.5, 0.25), allEventList, [], TowerDefenseEnum.CHARACTER_CAMP.ALL, -1)
