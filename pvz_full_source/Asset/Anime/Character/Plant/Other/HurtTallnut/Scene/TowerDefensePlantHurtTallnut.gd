@tool
extends TowerDefensePlant

@onready var timerComponent: TimerComponent = %TimerComponent

var StartHP = 2000.0


func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if instance.hitpoints > StartHP:
        instance.DealHurt(instance.hitpoints - StartHP, false)
    if !timerComponent.IsRunning("Health"):
        timerComponent.Run("Health", 1.0)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if IsDie():
        return
    if instance.hitpoints >= config.hitpoints:
        return



func Timeout(timerName: String) -> void :
    match timerName:
        "Health":
            Health(0.01 * instance.hitpointsSave)
            if instance.hitpoints >= instance.hitpointsSave:
                instance.hitpoints = instance.hitpointsSave
            timerComponent.Run("Health", 1.0)
