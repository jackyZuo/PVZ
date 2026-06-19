@tool
extends TowerDefensePlant

const HOT_DOG_SKIN_3_1 = preload("uid://b15hq5knf1462")
const HOT_DOG_SKIN_3_2 = preload("uid://dpb542keiv7j8")
const HOT_DOG_SKIN_3_3 = preload("uid://dp84ritbd4lbw")
const HOT_DOG_SKIN_4_1 = preload("uid://bwhn21u7l6hxa")
const HOT_DOG_SKIN_4_2 = preload("uid://b3c8rks3u7ldu")
const HOT_DOG_SKIN_4_3 = preload("uid://doxybk50iiwhe")
const HOT_DOG_SKIN_6_1 = preload("uid://b6lxv4s7mmh1c")
const HOT_DOG_SKIN_6_2 = preload("uid://bbbscktm0lt4a")
const HOT_DOG_SKIN_6_3 = preload("uid://dciued0lcnkxo")
const HOT_DOG_SKIN_7_2 = preload("uid://kn34pg26s2n")
const HOT_DOG_SKIN_7_2_2 = preload("uid://ciw3bqm4vccey")
const HOT_DOG_SKIN_7_2_3 = preload("uid://bj8vrr866kdo2")
const HOT_DOG_SKIN_7_3 = preload("uid://ja25qci6b505")
const HOT_DOG_SKIN_7_3_3 = preload("uid://bw0wgcemhi40e")
const HOT_DOG_SKIN_7_4 = preload("uid://b2iah3f5ft2t5")
const HOT_DOG_SKIN_7_4_2 = preload("uid://cii3syd5r3q5q")
const HOT_DOG_SKIN_7_4_3 = preload("uid://dlsvytiqbcbt2")
const HOT_DOG_SKIN_7_5 = preload("uid://cghcs27icauh4")
const HOT_DOG_SKIN_7_5_3 = preload("uid://bdwsmked5boiu")
const HOT_DOG_SKIN_7_6 = preload("uid://df0v50tov07ky")
const HOT_DOG_SKIN_7_6_2 = preload("uid://b3r7s1txwktrs")
const HOT_DOG_SKIN_7_6_3 = preload("uid://cd6irfup6sokx")

const HOT_DOG_0001_9 = preload("uid://6xhwx5v733xs")
const HOT_DOG_0001_9_CRACKED_1 = preload("uid://kddmvlhxk80f")
const HOT_DOG_0001_9_CRACKED_2 = preload("uid://bt2crx2aj2b2b")
const HOT_DOG_0002_8 = preload("uid://8dnfdnmf4xxe")
const HOT_DOG_0002_8_CRACKED_1 = preload("uid://u14pwe08qshs")
const HOT_DOG_0002_8_CRACKED_2 = preload("uid://vtktjc5ueuwf")
const HOT_DOG_0004_6 = preload("uid://bmgefsot5bcmf")
const HOT_DOG_0004_6_CRACKED_1 = preload("uid://clxq2sslv2v7o")
const HOT_DOG_0004_6_CRACKED_2 = preload("uid://b7ejbiskk5r6v")


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

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[0].projectileResource.projectileData.skinName = "Pow"
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[1].projectileResource.projectileData.skinName = "Pow"
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[2].projectileResource.projectileData.skinName = "Cask"
        fireComponent.fireCheckList[0].projectile.projectileWeight[1].projectileResource.projectileData.skinName = "Cask"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[0].projectileResource.projectileData.skinName = "Pow"
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[1].projectileResource.projectileData.skinName = "Pow"
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[2].projectileResource.projectileData.skinName = "Cask"
        fireComponent.fireCheckList[0].projectile.projectileWeight[1].projectileResource.projectileData.skinName = "Cask"
    else:
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[0].projectileResource.projectileData.skinName = "Default"
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[1].projectileResource.projectileData.skinName = "Default"
        fireComponent.fireCheckList[0].projectile.projectileWeight[0].projectileResource.projectileWeight[2].projectileResource.projectileData.skinName = "Default"
        fireComponent.fireCheckList[0].projectile.projectileWeight[1].projectileResource.projectileData.skinName = "Default"

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            sprite.SetReplace("HotDog_0001_9.png", HOT_DOG_0001_9)
            sprite.SetReplace("HotDog_0002_8.png", HOT_DOG_0002_8)
            sprite.SetReplace("HotDog_0004_6.png", HOT_DOG_0004_6)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("HotDog_skin3_1.png", HOT_DOG_SKIN_3_1)
                sprite.SetReplace("HotDog_skin4_1.png", HOT_DOG_SKIN_4_1)
                sprite.SetReplace("HotDog_skin6_1.png", HOT_DOG_SKIN_6_1)
                sprite.SetReplace("HotDog_skin7_2.png", HOT_DOG_SKIN_7_2)
                sprite.SetReplace("HotDog_skin7_3.png", HOT_DOG_SKIN_7_3)
                sprite.SetReplace("HotDog_skin7_4.png", HOT_DOG_SKIN_7_4)
                sprite.SetReplace("HotDog_skin7_5.png", HOT_DOG_SKIN_7_5)
                sprite.SetReplace("HotDog_skin7_6.png", HOT_DOG_SKIN_7_6)
        "Damage1":
            sprite.SetReplace("HotDog_0001_9.png", HOT_DOG_0001_9_CRACKED_1)
            sprite.SetReplace("HotDog_0002_8.png", HOT_DOG_0002_8_CRACKED_1)
            sprite.SetReplace("HotDog_0004_6.png", HOT_DOG_0004_6_CRACKED_1)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("HotDog_skin3_1.png", HOT_DOG_SKIN_3_2)
                sprite.SetReplace("HotDog_skin4_1.png", HOT_DOG_SKIN_4_2)
                sprite.SetReplace("HotDog_skin6_1.png", HOT_DOG_SKIN_6_2)
                sprite.SetReplace("HotDog_skin7_2.png", HOT_DOG_SKIN_7_2_2)
                sprite.SetReplace("HotDog_skin7_4.png", HOT_DOG_SKIN_7_4_2)
                sprite.SetReplace("HotDog_skin7_6.png", HOT_DOG_SKIN_7_6_2)
        "Damage2":
            sprite.SetReplace("HotDog_0001_9.png", HOT_DOG_0001_9_CRACKED_2)
            sprite.SetReplace("HotDog_0002_8.png", HOT_DOG_0002_8_CRACKED_2)
            sprite.SetReplace("HotDog_0004_6.png", HOT_DOG_0004_6_CRACKED_2)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("HotDog_skin3_1.png", HOT_DOG_SKIN_3_3)
                sprite.SetReplace("HotDog_skin4_1.png", HOT_DOG_SKIN_4_3)
                sprite.SetReplace("HotDog_skin6_1.png", HOT_DOG_SKIN_6_3)
                sprite.SetReplace("HotDog_skin7_2.png", HOT_DOG_SKIN_7_2_3)
                sprite.SetReplace("HotDog_skin7_3.png", HOT_DOG_SKIN_7_3_3)
                sprite.SetReplace("HotDog_skin7_4.png", HOT_DOG_SKIN_7_4_3)
                sprite.SetReplace("HotDog_skin7_5.png", HOT_DOG_SKIN_7_5_3)
                sprite.SetReplace("HotDog_skin7_6.png", HOT_DOG_SKIN_7_6_3)

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
