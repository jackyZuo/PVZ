@tool
extends TowerDefensePlant

@onready var rayCast2D2: RayCast2D = %RayCast2D2
@onready var rayCast2D3: RayCast2D = %RayCast2D3

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

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    rayCast2D2.position.y = TowerDefenseManager.GetMapGridSize().y
    rayCast2D3.position.y = - TowerDefenseManager.GetMapGridSize().y

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Pea")
    fireInterval = data.get("fireInterval", 1.5)
