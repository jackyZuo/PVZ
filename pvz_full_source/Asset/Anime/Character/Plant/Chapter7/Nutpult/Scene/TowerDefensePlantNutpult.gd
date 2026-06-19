@tool
extends TowerDefensePlant

var NUT_PULT_SKIN_1_1 = preload("uid://ctkrk4pg3v5g8")
var NUT_PULT_SKIN_1_2 = preload("uid://btg4rkfp3v5c0")
var NUT_PULT_SKIN_1_3 = preload("uid://bnsn0dnoeyfh0")

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

@export var projectileName: String = "Nut":
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
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "Egg"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Egg"
    else:
        skinName = "Default"

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("NutPult_skin1_1.png", NUT_PULT_SKIN_1_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("NutPult_skin1_1.png", NUT_PULT_SKIN_1_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("NutPult_skin1_1.png", NUT_PULT_SKIN_1_3)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "skinName": skinName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Nut")
    skinName = data.get("skinName", "Default")
    fireInterval = data.get("fireInterval", 3.0)
