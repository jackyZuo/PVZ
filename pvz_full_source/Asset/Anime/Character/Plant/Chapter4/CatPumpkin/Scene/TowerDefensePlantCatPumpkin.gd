@tool
extends TowerDefensePlant

const CAT_PUMPKIN_SKIN_1_1 = preload("uid://b808y0h42q37k")
const CAT_PUMPKIN_SKIN_1_2 = preload("uid://dly80yge8yx84")
const CAT_PUMPKIN_SKIN_1_3 = preload("uid://bgnypakc5u5pl")

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 2:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Spike":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if !inGame:
        sprite.back.z_index = 0
    if currentCustom.has("Custom0"):
        sprite.back.SetFliter("Pumpkin_back", false)
        sprite.back.SetFliter("skin2", true)

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        sprite.back.SetFliter("Pumpkin_back", false)
        sprite.back.SetFliter("skin2", true)
    else:
        sprite.back.SetFliter("Pumpkin_back", true)
        sprite.back.SetFliter("skin2", false)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("CatPumpkin_skin1_1.png", CAT_PUMPKIN_SKIN_1_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("CatPumpkin_skin1_1.png", CAT_PUMPKIN_SKIN_1_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("CatPumpkin_skin1_1.png", CAT_PUMPKIN_SKIN_1_3)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 2)
    projectileName = data.get("projectileName", "Spike")
    fireInterval = data.get("fireInterval", 1.5)
