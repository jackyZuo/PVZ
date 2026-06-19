@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var growUpComponent: GrowUpComponent = %GrowUpComponent
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkScaredShape: CollisionShape2D = %CheckScaredShape

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

@export var projectileName: String = "Puff":
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

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    checkScaredShape.shape.size = TowerDefenseManager.GetMapGridSize() * Vector2.ONE * 2.75


func GowUp(reach: int) -> void :
    match reach:
        0:
            sunNum = 25
            produceComponent.num = sunNum
            fireComponent.fireCheckList[0].projectile.projectileData.baseDamage = 40.0

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "growUpTime": growUpTime, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Puff")
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 15)
    growUpTime = data.get("growUpTime", 60.0)
    fireInterval = data.get("fireInterval", 1.5)
