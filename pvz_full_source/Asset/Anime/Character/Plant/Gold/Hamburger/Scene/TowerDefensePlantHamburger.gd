@tool
extends TowerDefensePlant

const HAMBURGER_0004_8 = preload("uid://cdyxcmno3lbul")
const HAMBURGER_0004_8_CRACKED_2 = preload("uid://c88v00eh32drf")
const HAMBURGER_0007_5 = preload("uid://y475jqw773qy")
const HAMBURGER_0007_5_CRACKED_2 = preload("uid://cxr5yeh7tvshg")
const HAMBURGER_0009_3 = preload("uid://bjb1lpeapkdcc")
const HAMBURGER_0009_3_CRACKED_1 = preload("uid://cqi6388l2ywvi")
const HAMBURGER_0009_3_CRACKED_2 = preload("uid://bpmrgqnlh2spp")
const HAMBURGER_0011_1 = preload("uid://dpipyjlhirdmw")
const HAMBURGER_0011_1_CRACKED_1 = preload("uid://d08qy1cn78ee1")
const HAMBURGER_0011_1_CRACKED_2 = preload("uid://b1bnqu2orejfu")

const HAMBURGER_SKIN_4_1 = preload("uid://jbyw6u6588t7")
const HAMBURGER_SKIN_4_3 = preload("uid://b7w3ndq734j6u")
const HAMBURGER_SKIN_5_1 = preload("uid://cbsvs0g4yvx4k")
const HAMBURGER_SKIN_5_2 = preload("uid://braukofb8mhes")
const HAMBURGER_SKIN_5_3 = preload("uid://vujm3aqinku7")

@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var fireComponent: FireComponent = %FireComponent

@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval
@export var sunNum: int = 50:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

@export var fireInterval: float = 2.0:
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

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            sprite.SetReplace("hamburger_0009_3.png", HAMBURGER_0009_3)
            sprite.SetReplace("hamburger_0011_1.png", HAMBURGER_0011_1)
            sprite.SetReplace("hamburger_0004_8.png", HAMBURGER_0004_8)
            sprite.SetReplace("hamburger_0007_5.png", HAMBURGER_0007_5)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("hamburger_skin5_1.png", HAMBURGER_SKIN_5_1)
                sprite.SetReplace("hamburger_skin4_1.png", HAMBURGER_SKIN_4_1)
        "Damage1":
            sprite.SetReplace("hamburger_0009_3.png", HAMBURGER_0009_3_CRACKED_1)
            sprite.SetReplace("hamburger_0011_1.png", HAMBURGER_0011_1_CRACKED_1)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("hamburger_skin5_1.png", HAMBURGER_SKIN_5_2)
        "Damage2":
            sprite.SetReplace("hamburger_0009_3.png", HAMBURGER_0009_3_CRACKED_2)
            sprite.SetReplace("hamburger_0011_1.png", HAMBURGER_0011_1_CRACKED_2)
            sprite.SetReplace("hamburger_0004_8.png", HAMBURGER_0004_8_CRACKED_2)
            sprite.SetReplace("hamburger_0007_5.png", HAMBURGER_0007_5_CRACKED_2)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("hamburger_skin5_1.png", HAMBURGER_SKIN_5_3)
                sprite.SetReplace("hamburger_skin4_1.png", HAMBURGER_SKIN_4_3)

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
    sunNum = data.get("sunNum", 50)
    fireNum = data.get("fireNum", 1)
    fireInterval = data.get("fireInterval", 2.0)
