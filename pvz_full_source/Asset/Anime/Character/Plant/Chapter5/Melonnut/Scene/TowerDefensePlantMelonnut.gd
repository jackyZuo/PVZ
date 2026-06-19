@tool
extends TowerDefensePlant

const MELON_NUT_SKIN_1_1 = preload("uid://cx7gtgw52t3oj")
const MELON_NUT_SKIN_1_2 = preload("uid://cv0bbs3qujxi3")
const MELON_NUT_SKIN_1_3 = preload("uid://lxqv1h150djq")
const MELON_NUT_SKIN_2_1 = preload("uid://bhavtiic64dep")
const MELON_NUT_SKIN_2_2 = preload("uid://cq6mgcgj2rv33")
const MELON_NUT_SKIN_2_3 = preload("uid://bq5nd3utxer1h")

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

@export var projectileName: String = "Melon":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName


func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("MelonNut_skin1_1.png", MELON_NUT_SKIN_1_1)
                sprite.SetReplace("MelonNut_skin2_1.png", MELON_NUT_SKIN_2_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("MelonNut_skin1_1.png", MELON_NUT_SKIN_1_2)
                sprite.SetReplace("MelonNut_skin2_1.png", MELON_NUT_SKIN_2_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("MelonNut_skin1_1.png", MELON_NUT_SKIN_1_3)
                sprite.SetReplace("MelonNut_skin2_1.png", MELON_NUT_SKIN_2_3)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Melon")
    fireInterval = data.get("fireInterval", 3.0)
