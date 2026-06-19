@tool
extends TowerDefensePlant
const ICE_TALLNUT_SKIN_1_1 = preload("uid://kbwg7hb8cnua")
const ICE_TALLNUT_SKIN_1_2 = preload("uid://dw7wbbuiiyg2c")
const ICE_TALLNUT_SKIN_1_3 = preload("uid://e8txsjxgr6ww")
const ICE_TALLNUT_SKIN_2_1 = preload("uid://chl104vmmo0qj")
const ICE_TALLNUT_SKIN_2_2 = preload("uid://ia8inaliwjbh")
const ICE_TALLNUT_SKIN_2_3 = preload("uid://oddokus1tw4f")
const ICE_TALLNUT_SKIN_3_1 = preload("uid://cqtqaal7q7uvy")
const ICE_TALLNUT_SKIN_3_2 = preload("uid://c8u3lng7dqlpx")
const ICE_TALLNUT_SKIN_3_3 = preload("uid://4246khj1sxop")

@onready var fireComponent: FireComponent = %FireComponent

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

@export var projectileName: String = "SnowPea":
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

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "Armor"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Armor"
    else:
        skinName = "Default"

func DestroySet() -> void :
    CreateColdEffect(camp, gridPos)
    await get_tree().physics_frame

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("IceTallnut_skin1_1.png", ICE_TALLNUT_SKIN_1_1)
                sprite.SetReplace("IceTallnut_skin2_1.png", ICE_TALLNUT_SKIN_2_1)
                sprite.SetReplace("IceTallnut_skin3_1.png", ICE_TALLNUT_SKIN_3_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("IceTallnut_skin1_1.png", ICE_TALLNUT_SKIN_1_2)
                sprite.SetReplace("IceTallnut_skin2_1.png", ICE_TALLNUT_SKIN_2_2)
                sprite.SetReplace("IceTallnut_skin3_1.png", ICE_TALLNUT_SKIN_3_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("IceTallnut_skin1_1.png", ICE_TALLNUT_SKIN_1_3)
                sprite.SetReplace("IceTallnut_skin2_1.png", ICE_TALLNUT_SKIN_2_3)
                sprite.SetReplace("IceTallnut_skin3_1.png", ICE_TALLNUT_SKIN_3_3)

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        character.Hurt(num / 2.0, false)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "skinName": skinName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "SnowPea")
    skinName = data.get("skinName", "Default")
    fireInterval = data.get("fireInterval", 1.5)
