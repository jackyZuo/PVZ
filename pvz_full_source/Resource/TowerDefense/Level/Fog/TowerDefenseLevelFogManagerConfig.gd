class_name TowerDefenseLevelFogManagerConfig extends Resource

@export var open: bool = false
@export var beginColumn: int = 5

func Init(fogManagerData: Dictionary) -> void :
    open = fogManagerData.get("Open", false)
    beginColumn = fogManagerData.get("BeginColumn", 5)

func Export() -> Dictionary:
    return {
        "Open": open, 
        "BeginColumn": beginColumn
    }
