@tool
extends TowerDefensePlant

@onready var magnetComponent: MagnetComponent = %MagnetComponent

@export var breakDownTime: float = 15.0:
    set(_breakDownTime):
        breakDownTime = _breakDownTime
        if is_node_ready():
            magnetComponent.breakDownTime = breakDownTime

func ExportVariantSave() -> Dictionary:
    return {
        "breakDownTime": breakDownTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    breakDownTime = data.get("breakDownTime", 15.0)
