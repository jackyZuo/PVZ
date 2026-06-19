@tool
extends TowerDefensePlant

const PUMPKIN_SUN_SKIN_1_1 = preload("uid://cvjt7q0lfkx1l")
const PUMPKIN_SUN_SKIN_1_2 = preload("uid://cn3bp63vbxep3")
const PUMPKIN_SUN_SKIN_1_3 = preload("uid://b24vuwof58261")

@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var fireComponent: FireComponent = %FireComponent

@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval

@export var sunNum: int = 25:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

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


func FireReady() -> void :
    if fireComponent.runningCheckId == 0:
        fireComponent.fireAnimeClips = "Fire2"
        fireComponent.fireProjectileList[0].checkProjectileId = 0
    else:
        fireComponent.fireAnimeClips = "Fire"
        fireComponent.fireProjectileList[0].checkProjectileId = 1

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("PumpkinA_skin1_1.png", PUMPKIN_SUN_SKIN_1_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("PumpkinA_skin1_1.png", PUMPKIN_SUN_SKIN_1_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("PumpkinA_skin1_1.png", PUMPKIN_SUN_SKIN_1_3)

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {"produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "fireNum": fireNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
    fireNum = data.get("fireNum", 2)
    fireInterval = data.get("fireInterval", 1.5)
