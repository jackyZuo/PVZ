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

@export var projectileName: String = "WinterMelon":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

var skinName: String = "Default":
    set(_skinName):
        skinName = _skinName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileData.skinName = skinName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if currentCustom.has("Custom0"):
        skinName = "Frost"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Frost"
    else:
        skinName = "Default"

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "skinName": skinName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "WinterMelon")
    skinName = data.get("skinName", "Default")
    fireInterval = data.get("fireInterval", 3.0)
