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
@export var sunNum: int = 15:
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

func GowUp(reach: int) -> void :
    match reach:
        0:
            sunNum = 25
            produceComponent.num = - sunNum if instance.hypnoses else sunNum

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.num = - sunNum if instance.hypnoses else sunNum

func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "growUpTime": growUpTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 15)
    growUpTime = data.get("growUpTime", 60.0)
