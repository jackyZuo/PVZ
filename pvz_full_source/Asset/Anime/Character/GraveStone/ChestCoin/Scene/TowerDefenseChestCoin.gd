@tool
extends TowerDefenseGravestone

const CHEST_COIN_WATER_1 = preload("uid://bdcvatet7ks35")
const CHEST_COIN_WATER_2 = preload("uid://fmoke6o3c88f")
const CHEST_COIN_WATER_3 = preload("uid://1vj81vk4dvil")
const CHEST_COIN_WATER_4 = preload("uid://dtfupjwagghmo")
const CHEST_COIN_WATER_5 = preload("uid://o6x68dbqcw44")

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    add_to_group("ChestCoin")
    remove_from_group("Gravestone")
    if is_instance_valid(cell) && cell.IsWater():
        shadowSprite.visible = false
        sprite.SetReplace("CoinChest1_1.png", CHEST_COIN_WATER_1)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    if is_instance_valid(cell) && cell.IsWater():
        match damangePointName:
            "Damage0":
                sprite.SetReplace("CoinChest1_1.png", CHEST_COIN_WATER_1)
            "Damage1":
                sprite.SetReplace("CoinChest1_1.png", CHEST_COIN_WATER_2)
            "Damage2":
                sprite.SetReplace("CoinChest1_1.png", CHEST_COIN_WATER_3)
            "Damage3":
                sprite.SetReplace("CoinChest1_1.png", CHEST_COIN_WATER_4)
            "Damage4":
                sprite.SetReplace("CoinChest1_1.png", CHEST_COIN_WATER_5)

func DestroySet() -> void :
    if (Global.isEditor && Global.enterLevelMode == "DiyLevel") || Global.enterLevelMode == "LoadLevel" || Global.enterLevelMode == "OnlineLevel":
        return
    if randf() > 0.0025:
            for i in 8:
                var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                item.gridPos = gridPos
    else:
        for i in 2:
            var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            item.gridPos = gridPos
    await get_tree().physics_frame
