@tool
extends TowerDefensePlant

@onready var chomperComponent: ChomperComponent = %ChomperComponent
@onready var bloverComponent: BloverComponent = %BloverComponent
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape

@export var chewTime: float = 30.0:
    set(_chewTime):
        chewTime = _chewTime
        if !is_node_ready():
            await ready
        chomperComponent.chewTime = chewTime

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 1.75

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "blow":
            bloverComponent.ExecuteLine(gridPos.y)
            BattleEventBus.blowLineEffectEmit.emit(gridPos.y)

func ExportVariantSave() -> Dictionary:
    return {
        "chewTime": chewTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    chewTime = data.get("chewTime", 30.0)
