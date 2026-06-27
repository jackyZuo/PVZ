@tool
extends TowerDefensePlant

@onready var rayCast2D2: RayCast2D = %RayCast2D2
@onready var rayCast2D3: RayCast2D = %RayCast2D3
@onready var fireComponentExtendCactus: FireComponentExtendCactus = %FireComponentExtendCactus
@onready var fireComponent: FireComponent = %FireComponent

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

@export var projectileName: String = "IceSpike":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName
        fireComponent.fireCheckList[1].projectile.projectileName = projectileName

var up: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    rayCast2D2.position.y = TowerDefenseManager.GetMapGridSize().y
    rayCast2D3.position.y = - TowerDefenseManager.GetMapGridSize().y
    fireComponentExtendCactus.upOver.connect(UpOver)
    fireComponentExtendCactus.downOver.connect(DownOver)

func IdleEntered() -> void :
    super.IdleEntered()
    if !fireComponentExtendCactus.IsUp():
        sprite.SetAnimation("Idle", true, 0.1)
    else:
        sprite.SetAnimation("UpIdle", true, 0.1)

func DownOver() -> void :
    fireComponent.fireNum = 1

func UpOver() -> void :
    fireComponent.fireNum = 2

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "up": up, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "IceSpike")
    up = data.get("up", false)
    fireInterval = data.get("fireInterval", 1.5)
