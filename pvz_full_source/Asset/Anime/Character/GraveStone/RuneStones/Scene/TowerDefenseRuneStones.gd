@tool
extends TowerDefenseGravestone

const RUNE_STONES_WATER_1 = preload("uid://drim0rxao2i1e")
const RUNE_STONES_WATER_2 = preload("uid://bp8idfpt8pjls")
const RUNE_STONES_WATER_3 = preload("uid://c4fmainbpf3b7")
const RUNE_STONES_WATER_4 = preload("uid://cnjnq72j50hji")
const RUNE_STONES_WATER_5 = preload("uid://daebeitjtpwfk")

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    remove_from_group("Gravestone")
    if is_instance_valid(cell) && cell.IsWater():
        shadowSprite.visible = false
        sprite.SetReplace("RuneStones3_1.png", RUNE_STONES_WATER_1)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    if is_instance_valid(cell) && cell.IsWater():
        match damangePointName:
            "Damage0":
                sprite.SetReplace("RuneStones3_1.png", RUNE_STONES_WATER_1)
            "Damage1":
                sprite.SetReplace("RuneStones3_1.png", RUNE_STONES_WATER_2)
            "Damage2":
                sprite.SetReplace("RuneStones3_1.png", RUNE_STONES_WATER_3)
            "Damage3":
                sprite.SetReplace("RuneStones3_1.png", RUNE_STONES_WATER_4)
            "Damage4":
                sprite.SetReplace("RuneStones3_1.png", RUNE_STONES_WATER_5)
