@tool
extends TowerDefensePlant

@onready var produceComponent: ProduceComponent = %ProduceComponent


@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if is_node_ready():
            produceComponent.produceInterval = produceInterval

@export var sunNum: int = 25:
    set(_sunNum):
        sunNum = _sunNum
        if is_node_ready():
            produceComponent.num = sunNum

@export_enum("Sun", "BrainSun", "JalaSun", "Coin") var produceType: String = "Sun":
    set(_produceType):
        produceType = _produceType
        if is_node_ready():
            produceComponent.produceType = produceType

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    produceComponent.produceInterval = produceInterval
    produceComponent.num = sunNum


func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale * 0.5

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.alive = !instance.hypnoses

func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
