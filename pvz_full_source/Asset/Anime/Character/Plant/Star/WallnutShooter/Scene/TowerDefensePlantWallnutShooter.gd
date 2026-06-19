@tool
extends TowerDefensePlant

const WALLNUT_SHOOTER = preload("uid://dtaxmmgke1nkh")
const WALLNUT_SHOOTER_BOOM = preload("uid://cn4ms671wsyqg")
const WALLNUT_SHOOTER_BOOM_DAMAGE_1 = preload("uid://cwgg1u47m01gs")
const WALLNUT_SHOOTER_BOOM_DAMAGE_2 = preload("uid://bu75ftg0rf725")
const WALLNUT_SHOOTER_DAMAGE_1 = preload("uid://cpj46i6gydv5s")
const WALLNUT_SHOOTER_DAMAGE_2 = preload("uid://dd7025whr48re")

var isBoom: bool = false: set = SetIsBoom
var currentDamagePoint: String = "Damage0"

func SetIsBoom(_isBoom: bool) -> void :
    isBoom = _isBoom
    if isBoom:
        sprite.SetFliters(["anim_face2"], true)
        sprite.SetFliters(["anim_face"], false)
    else:
        sprite.SetFliters(["anim_face2"], false)
        sprite.SetFliters(["anim_face"], true)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    currentDamagePoint = damangePointName
    match damangePointName:
        "Damage0":
            sprite.SetReplace("WallnutShooter.png", WALLNUT_SHOOTER)
            sprite.SetReplace("WallnutShooter_boom.png", WALLNUT_SHOOTER_BOOM)
        "Damage1":
            sprite.SetReplace("WallnutShooter.png", WALLNUT_SHOOTER_DAMAGE_1)
            sprite.SetReplace("WallnutShooter_boom.png", WALLNUT_SHOOTER_BOOM_DAMAGE_1)
        "Damage2":
            sprite.SetReplace("WallnutShooter.png", WALLNUT_SHOOTER_DAMAGE_2)
            sprite.SetReplace("WallnutShooter_boom.png", WALLNUT_SHOOTER_BOOM_DAMAGE_2)


func Restore() -> void :
    isBoom = randf() < 0.05

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Fire":
            CreateBowling()

func CreateBowling() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var bowling_name: String = "PlantBowlingWallnutShooterBoom" if isBoom else "PlantBowlingWallnutShooterNormal"
    var bowling = CreateCharacter(bowling_name, global_position, gridPos, groundHeight)
    if instance.hypnoses:
        bowling.Hypnoses()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, bowling)
            MultiPlayerManager.SendSpawnCharacterAt(bowling_name, gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, instance.hypnoses, 0.0, true, global_position.x, global_position.y, false, groundHeight)
    match currentDamagePoint:
        "Damage0":
            bowling.sprite.SetReplace("WallnutShooter.png", WALLNUT_SHOOTER)
            bowling.sprite.SetReplace("WallnutShooter_boom.png", WALLNUT_SHOOTER_BOOM)
        "Damage1":
            bowling.sprite.SetReplace("WallnutShooter.png", WALLNUT_SHOOTER_DAMAGE_1)
            bowling.sprite.SetReplace("WallnutShooter_boom.png", WALLNUT_SHOOTER_BOOM_DAMAGE_1)
        "Damage2":
            bowling.sprite.SetReplace("WallnutShooter.png", WALLNUT_SHOOTER_DAMAGE_2)

func ExportVariantSave() -> Dictionary:
    return {
        "isBoom": isBoom, 
        "currentDamagePoint": currentDamagePoint, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    isBoom = data.get("isBoom", false)
    currentDamagePoint = data.get("currentDamagePoint", "Damage0")
