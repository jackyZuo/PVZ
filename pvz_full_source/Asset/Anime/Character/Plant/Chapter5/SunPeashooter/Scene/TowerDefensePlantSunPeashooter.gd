@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
@onready var produceComponent: ProduceComponent = %ProduceComponent

@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval
@export var sunNum: int = 50:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "WhiteFirePea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {"produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 50)
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "WhiteFirePea")
    fireInterval = data.get("fireInterval", 1.5)
