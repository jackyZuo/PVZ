@tool
extends TowerDefensePlant

@onready var timerComponent: TimerComponent = %TimerComponent

@onready var attackComponent: AttackComponent = %AttackComponent

@export var attack: float = 20.0

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Destroy"):
        timerComponent.Run("Destroy", 10)

func Attack() -> void :
    attackComponent.AttackAllFlag(attack, TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY)

@warning_ignore("unused_parameter")
func Timeout(timerName: String) -> void :
    Destroy()

func ExportVariantSave() -> Dictionary:
    return {"attack": attack, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    attack = data.get("attack", 20.0)
    fireInterval = data.get("fireInterval", 1.5)
