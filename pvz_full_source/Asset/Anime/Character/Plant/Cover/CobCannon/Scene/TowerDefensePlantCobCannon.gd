@tool
extends TowerDefensePlant

@onready var cannonComponent: CannonComponent = %CannonComponent

@export var restTime: float = 35:
    set(_restTime):
        restTime = _restTime
        if !is_node_ready():
            await ready
        cannonComponent.restTime = restTime

func ExportVariantSave() -> Dictionary:
    return {
        "restTime": restTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    restTime = data.get("restTime", 35)
