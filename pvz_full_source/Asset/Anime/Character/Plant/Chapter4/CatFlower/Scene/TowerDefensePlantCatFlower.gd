@tool
extends TowerDefensePlant

@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 10:
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

@export var projectileName: String = "Sun":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

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


func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    produceComponent.produceInterval = produceInterval
    produceComponent.num = sunNum

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Sun")
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
    fireInterval = data.get("fireInterval", 10)
