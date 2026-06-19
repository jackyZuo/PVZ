@tool
extends TowerDefensePlant

@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var growUpComponent: GrowUpComponent = %GrowUpComponent

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

@export var growUpTime: float = 60.0:
    set(_growUpTime):
        growUpTime = _growUpTime
        if !is_node_ready():
            await ready
        growUpComponent.growUpTime[0] = growUpTime

@export var growUpSunNum: int = 50:
    set(_growUpSunNum):
        growUpSunNum = _growUpSunNum

@export_enum("Sun", "BrainSun", "JalaSun", "Coin") var produceType: String = "Sun":
    set(_produceType):
        produceType = _produceType
        if !is_node_ready():
            await ready
        produceComponent.produceType = produceType

func GowUp(reach: int) -> void :
    match reach:
        0:
            produceComponent.num = growUpSunNum

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "growUpTime": growUpTime, 
        "growUpSunNum": growUpSunNum, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
    growUpTime = data.get("growUpTime", 60.0)
    growUpSunNum = data.get("growUpSunNum", 50)
