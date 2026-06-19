@tool
extends TowerDefenseGravestone

const RUNE_STONESD_WATER_1 = preload("uid://c8inmwponajg")
const RUNE_STONESD_WATER_2 = preload("uid://cfifstkfddtf5")
const RUNE_STONESD_WATER_3 = preload("uid://boxryb6nnub52")
const RUNE_STONESD_WATER_4 = preload("uid://pnm35lep2vu4")
const RUNE_STONESD_WATER_5 = preload("uid://gnksay5ffiy3")

const CHERRY_BOMB_EXPLOSION = preload("uid://cibtjjjomdxnh")

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var boom: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    remove_from_group("Gravestone")
    if is_instance_valid(cell) && cell.IsWater():
        shadowSprite.visible = false
        sprite.SetReplace("RuneStones2_1.png", RUNE_STONESD_WATER_1)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    if is_instance_valid(cell) && cell.IsWater():
        match damangePointName:
            "Damage0":
                sprite.SetReplace("RuneStones2_1.png", RUNE_STONESD_WATER_1)
            "Damage1":
                sprite.SetReplace("RuneStones2_1.png", RUNE_STONESD_WATER_2)
            "Damage2":
                sprite.SetReplace("RuneStones2_1.png", RUNE_STONESD_WATER_3)
            "Damage3":
                sprite.SetReplace("RuneStones2_1.png", RUNE_STONESD_WATER_4)
            "Damage4":
                sprite.SetReplace("RuneStones2_1.png", RUNE_STONESD_WATER_5)

func DestroySet() -> void :
    if boom:
        return
    boom = true
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(CHERRY_BOMB_EXPLOSION, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
    await get_tree().physics_frame
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.5, 1.5), eventList, [], TowerDefenseEnum.CHARACTER_CAMP.NOONE, -1)
    AudioManager.AudioPlay("ExplodeCherrybomb", AudioManagerEnum.TYPE.SFX)
    CraterCreate(true)
