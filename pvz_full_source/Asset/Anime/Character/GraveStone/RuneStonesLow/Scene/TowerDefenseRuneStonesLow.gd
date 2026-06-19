@tool
extends TowerDefenseGravestone

const RUNE_STONES_WATER_1 = preload("uid://cjd6af321g5xm")
const RUNE_STONES_WATER_2 = preload("uid://bwaqfa2ivxpg1")
const RUNE_STONES_WATER_3 = preload("uid://d026tplpd0elk")
const RUNE_STONES_WATER_4 = preload("uid://cfoggnl858a8o")
const RUNE_STONES_WATER_5 = preload("uid://cbby5m82o0uy1")

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    remove_from_group("Gravestone")
    if is_instance_valid(cell) && cell.IsWater():
        shadowSprite.visible = false
        sprite.SetReplace("RuneStones1_1.png", RUNE_STONES_WATER_1)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    if is_instance_valid(cell) && cell.IsWater():
        match damangePointName:
            "Damage0":
                sprite.SetReplace("RuneStones1_1.png", RUNE_STONES_WATER_1)
            "Damage1":
                sprite.SetReplace("RuneStones1_1.png", RUNE_STONES_WATER_2)
            "Damage2":
                sprite.SetReplace("RuneStones1_1.png", RUNE_STONES_WATER_3)
            "Damage3":
                sprite.SetReplace("RuneStones1_1.png", RUNE_STONES_WATER_4)
            "Damage4":
                sprite.SetReplace("RuneStones1_1.png", RUNE_STONES_WATER_5)
