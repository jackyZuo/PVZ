@tool
extends TowerDefensePlant

@onready var produceComponent: ProduceComponent = %ProduceComponent

@export var sunNum: int = 25:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

@export_enum("Sun", "BrainSun", "JalaSun", "Coin") var produceType: String = "Sun":
    set(_produceType):
        produceType = _produceType
        if !is_node_ready():
            await ready
        produceComponent.produceType = produceType

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {
        "sunNum": sunNum, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    sunNum = data.get("sunNum", 25)
