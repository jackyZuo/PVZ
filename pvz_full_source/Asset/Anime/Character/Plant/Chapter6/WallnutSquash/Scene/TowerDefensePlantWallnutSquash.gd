@tool
extends TowerDefensePlant

@onready var squashComponent: SquashComponent = %SquashComponent

@onready var attackComponent: AttackComponent = %AttackComponent

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.hitpointsEmpty.disconnect(Destroy)
    instance.invincible = true
    instance.keepAlive = true
    await get_tree().create_timer(0.1, false).timeout
    if !attackComponent.CanAttack():
        instance.invincible = false

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale
    if !squashComponent.alive:
        if instance.hitpoints <= 0:
            ToSquash()
            return
    else:
        if instance.hitpoints <= 0:
            Destroy()
            return

func ToSquash() -> void :
    squashComponent.alive = true
    instance.hitpoints = 300
    instance.die = false
