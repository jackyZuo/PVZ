@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var squashComponent: SquashComponent = %SquashComponent

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var savePos: Vector2

var over: bool = false

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

func JumpDownSmash() -> void :
    CreateColdEffect(camp, gridPos)

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
