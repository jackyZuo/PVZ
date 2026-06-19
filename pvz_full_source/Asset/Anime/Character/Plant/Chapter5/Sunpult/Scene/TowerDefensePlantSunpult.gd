@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
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

@export var fireInterval: float = 3.0:
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

@export var projectileName: String = "Sunshroom":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

var skinName: String = "Default":
    set(_skinName):
        skinName = _skinName
        fireComponent.fireCheckList[0].projectile.projectileData.skinName = skinName

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "Santa"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Santa"
    else:
        skinName = "Default"

func GowUp(reach: int) -> void :
    match reach:
        0:
            sunNum = 25
            produceComponent.num = sunNum
            fireComponent.fireCheckList[0].projectile.projectileData.SetBaseDamage(80.0)
            fireComponent.fireCheckList[0].projectile.projectileData.SetScale(Vector2(1.5, 1.5))

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {"produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "growUpTime": growUpTime, 
        "fireNum": fireNum, 
        "projectileName": projectileName, 
        "skinName": skinName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 15)
    growUpTime = data.get("growUpTime", 60.0)
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Sunshroom")
    skinName = data.get("skinName", "Default")
    fireInterval = data.get("fireInterval", 3.0)
