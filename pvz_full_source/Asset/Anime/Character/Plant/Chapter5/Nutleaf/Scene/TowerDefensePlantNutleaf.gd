@tool
extends TowerDefensePlant

const NUTLEAF_BODY_2 = preload("uid://dtdgl22bp0385")
const NUTLEAF_BODY = preload("uid://d1rii54n6ebjt")
const NUTLEAF_LEAF_1 = preload("uid://du74itvg0v6tv")
const NUTLEAF_LEAF_1_1 = preload("uid://bvgoi2t06wkjk")
const NUTLEAF_LEAF_1_2 = preload("uid://0vubdg55l51c")
const NUTLEAF_LEAF_2 = preload("uid://befoku44k4xgc")
const NUTLEAF_LEAF_2_1 = preload("uid://cge2vjl6eavp8")
const NUTLEAF_LEAF_2_2 = preload("uid://r8qcq2gy4hcr")
const NUTLEAF_LEAF_7 = preload("uid://bh5hfx1p28j8d")
const NUTLEAF_LEAF_7_1 = preload("uid://61bj8cbbee7r")
const NUTLEAF_LEAF_7_2 = preload("uid://470542g6yvnh")
const NUTLEAF_NUT_1 = preload("uid://iybsy2qnq1y2")
const NUTLEAF_NUT_2 = preload("uid://c1l02a63ug03e")
const NUTLEAF_NUT = preload("uid://drkibciwd8v15")
const NUTLEAF_SKIN_1_1 = preload("uid://3bvuwmhgxhhs")
const NUTLEAF_SKIN_1_2 = preload("uid://c05sqej8dxhvo")
const NUTLEAF_SKIN_1_3 = preload("uid://c2o3ut38gtgc3")
const NUTLEAF_SKIN_2_1 = preload("uid://dloldmb0o56i0")
const NUTLEAF_SKIN_2_2 = preload("uid://f2hitkqe12ar")
const NUTLEAF_SKIN_2_3 = preload("uid://bwlwi5in4jse3")
const NUTLEAF_SKIN_7_1 = preload("uid://bpoowutc8v4dt")
const NUTLEAF_SKIN_7_2 = preload("uid://qkspyxn7b1sv")
const NUTLEAF_SKIN_7_3 = preload("uid://c1u4rrfof5oa7")

@onready var collisionShape: CollisionShape2D = %CollisionShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 4

func BlockCharacter() -> void :
    itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.EFFECT
    sprite.SetAnimation("Block", false, 0.1)
    sprite.AddAnimation("Idle", 0.0, true, 0.0)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Block":
            itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.PLANT

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            sprite.SetReplace("Nutleaf_body.png", NUTLEAF_BODY)
            sprite.SetReplace("Nutleaf_leaf1.png", NUTLEAF_LEAF_1)
            sprite.SetReplace("Nutleaf_leaf2.png", NUTLEAF_LEAF_2)
            sprite.SetReplace("Nutleaf_leaf7.png", NUTLEAF_LEAF_7)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("Nutleaf_skin1_1.png", NUTLEAF_SKIN_1_1)
                sprite.SetReplace("Nutleaf_skin2_1.png", NUTLEAF_SKIN_2_1)
                sprite.SetReplace("Nutleaf_skin7_1.png", NUTLEAF_SKIN_7_1)
        "Damage1":
            sprite.SetReplace("Nutleaf_leaf1.png", NUTLEAF_LEAF_1_1)
            sprite.SetReplace("Nutleaf_leaf2.png", NUTLEAF_LEAF_2_1)
            sprite.SetReplace("Nutleaf_leaf7.png", NUTLEAF_LEAF_7_1)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("Nutleaf_skin1_1.png", NUTLEAF_SKIN_1_2)
                sprite.SetReplace("Nutleaf_skin2_1.png", NUTLEAF_SKIN_2_2)
                sprite.SetReplace("Nutleaf_skin7_1.png", NUTLEAF_SKIN_7_2)
        "Damage2":
            sprite.SetReplace("Nutleaf_body.png", NUTLEAF_BODY_2)
            sprite.SetReplace("Nutleaf_leaf1.png", NUTLEAF_LEAF_1_2)
            sprite.SetReplace("Nutleaf_leaf2.png", NUTLEAF_LEAF_2_2)
            sprite.SetReplace("Nutleaf_leaf7.png", NUTLEAF_LEAF_7_2)
            if currentCustom.has("Custom0"):
                sprite.SetReplace("Nutleaf_skin1_1.png", NUTLEAF_SKIN_1_3)
                sprite.SetReplace("Nutleaf_skin2_1.png", NUTLEAF_SKIN_2_3)
                sprite.SetReplace("Nutleaf_skin7_1.png", NUTLEAF_SKIN_7_3)
