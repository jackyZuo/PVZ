@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
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


func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

    checkScaredShape.shape.size = TowerDefenseManager.GetMapGridSize() * Vector2.ONE * 2.75

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Puff")
    fireInterval = data.get("fireInterval", 1.5)
