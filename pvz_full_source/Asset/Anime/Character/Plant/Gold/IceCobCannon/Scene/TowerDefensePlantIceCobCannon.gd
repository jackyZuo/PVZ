@tool
extends TowerDefensePlant

@onready var cannonComponent: CannonComponent = %CannonComponent

@export var restTime: float = 30:
    set(_restTime):
        restTime = _restTime
        if !is_node_ready():
            await ready
        cannonComponent.restTime = restTime

var skinName: String = "Default":
    set(_skinName):
        skinName = _skinName
        cannonComponent.projectileData.skinName = skinName

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "IceCream"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "IceCream"
    else:
        skinName = "Default"

func ExportVariantSave() -> Dictionary:
    return {
        "restTime": restTime, 
        "skinName": skinName
    }

func ImportVariantSave(data: Dictionary) -> void :
    restTime = data.get("restTime", 30)
    skinName = data.get("skinName", "Default")
