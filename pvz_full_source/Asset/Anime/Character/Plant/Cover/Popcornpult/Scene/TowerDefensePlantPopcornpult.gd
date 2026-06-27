@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

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

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    fireInterval = data.get("fireInterval", 3.0)
