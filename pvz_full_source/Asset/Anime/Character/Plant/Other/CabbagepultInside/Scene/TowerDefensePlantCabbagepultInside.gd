@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

var maxFireNum: int = 5

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

@export var projectileName: String = "Cabbage":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    for plant in get_tree().get_nodes_in_group("PlantCabbagepultInside"):
        if plant == self:
            continue
        if plant.config.name == "PlantCabbagepultInside":
            plant.fireNum = mini(plant.fireNum + 1, maxFireNum)

func ExportVariantSave() -> Dictionary:
    return {
        "fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, 
        "maxFireNum": maxFireNum
    }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Cabbage")
    fireInterval = data.get("fireInterval", 3.0)
    maxFireNum = data.get("maxFireNum", 5)
