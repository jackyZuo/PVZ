@tool
extends TowerDefensePlant

@onready var squashComponent: SquashComponent = %SquashComponent

@onready var attackComponent: AttackComponent = %AttackComponent

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.invincible = true
    await get_tree().create_timer(0.5, false).timeout
    if !squashComponent.IsRunning():
        instance.invincible = false

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale
