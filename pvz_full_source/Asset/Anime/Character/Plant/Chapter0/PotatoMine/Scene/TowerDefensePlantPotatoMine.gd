@tool
extends TowerDefensePlant

@onready var potatoComponent: PotatoComponent = %PotatoComponent
@export var readyTime: float = 15.0:
    set(_readyTime):
        readyTime = _readyTime
        if !is_node_ready():
            await ready
        potatoComponent.readyTime = readyTime

func ReadyRise() -> void :
    potatoComponent.ReadyRise()

func ExportVariantSave() -> Dictionary:
    return {
        "readyTime": readyTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    readyTime = data.get("readyTime", 15.0)
