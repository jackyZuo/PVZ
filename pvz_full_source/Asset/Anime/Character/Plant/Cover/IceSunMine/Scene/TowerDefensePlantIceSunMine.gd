@tool
extends TowerDefensePlant

@onready var potatoComponent: PotatoComponent = %PotatoComponent

@export var eventList: Array[TowerDefenseCharacterEventBase] = []
@export var readyTime: float = 15.0:
    set(_readyTime):
        readyTime = _readyTime
        if !is_node_ready():
            await ready
        potatoComponent.readyTime = readyTime

func ReadyRise() -> void :
    potatoComponent.ReadyRise()

func Explode() -> void :
    CreateColdEffect(camp, gridPos, eventList)
    if instance.hypnoses:
        BrainSunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
    else:
        SunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)

func Cover(character: TowerDefenseCharacter) -> void :
    if character.config.name == "PlantSunMine":
        if character.potatoComponent.rise:
            ReadyRise()

func ExportVariantSave() -> Dictionary:
    return {
        "readyTime": readyTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    readyTime = data.get("readyTime", 15.0)
