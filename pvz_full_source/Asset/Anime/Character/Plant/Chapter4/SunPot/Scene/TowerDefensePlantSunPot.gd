@tool
extends TowerDefensePlant

@onready var produceComponent: ProduceComponent = %ProduceComponent

@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval

@export var sunNum: int = 25:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
