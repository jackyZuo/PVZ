@tool
extends TowerDefensePlant

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

@export var projectileName: String = "Spike":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName
        fireComponent.fireCheckList[1].projectile.projectileName = projectileName

func IdleEntered() -> void :
    super.IdleEntered()
    if !fireComponentExtendCactus.IsUp():
        sprite.SetAnimation("Idle", true, 0.1)
    else:
        sprite.SetAnimation("UpIdle", true, 0.1)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Spike")
    fireInterval = data.get("fireInterval", 1.5)
