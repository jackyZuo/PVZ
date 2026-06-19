@tool
extends TowerDefenseZombie

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")
const THJG_1 = preload("uid://d1s3xfn24qy5k")
const THJG_2 = preload("uid://5y7s57q3mo0d")
const THJG_3 = preload("uid://dr4snugqr4nug")
const THJG_4 = preload("uid://2id74xf8q2bt")
const THJG_5 = preload("uid://d2rvj1bfag3so")
const THJG_6 = preload("uid://douuu1u5yg5rr")

var halfHp: bool = false
var isAttack: bool = false

var purifyPacketName: String = "PlantWallnutABC_A"

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

func AttackEntered():
    super.AttackEntered()
    isAttack = true
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func AttackExited() -> void :
    super.AttackExited()
    isAttack = false
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper", "Zombie_outerarm_hand", "Zombie_outerarm_lower"], false)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            halfHp = true
            sprite.SetFliters(["Zombie_outerarm_upper"], true)
        "Head":
            DamagePartCreate("Head", sprite.head3, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))
        "ADamage1":
            sprite.head1.SetReplace("THJG_0017_1.png", THJG_1)
        "ADamage2":
            sprite.head1.SetReplace("THJG_0017_1.png", THJG_2)
        "BDamage0":
            purifyPacketName = "PlantWallnutABC_B"
            var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
            effect.global_position = global_position
            characterNode.add_child(effect)
            sprite.head1.visible = false
            sprite.head2.visible = true
        "BDamage1":
            sprite.head1.visible = false
            sprite.head2.visible = true
            sprite.head2.SetReplace("THJG_0013_5.png", THJG_3)
        "BDamage2":
            sprite.head1.visible = false
            sprite.head2.visible = true
            sprite.head2.SetReplace("THJG_0013_5.png", THJG_4)
        "CDamage0":
            purifyPacketName = "PlantWallnutABC_C"
            var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
            effect.global_position = global_position
            characterNode.add_child(effect)
            sprite.head2.visible = false
            sprite.head3.visible = true
        "CDamage1":
            sprite.head2.visible = false
            sprite.head3.visible = true
            sprite.head3.SetReplace("THJG_0010_8.png", THJG_5)
        "CDamage2":
            sprite.head2.visible = false
            sprite.head3.visible = true
            sprite.head3.SetReplace("THJG_0010_8.png", THJG_6)

func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    super.ArmorDamagePointReach(armorName, stage)
    if isAttack && HasShield() && stage > 0:
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(purifyPacketName)
    if cell.CanPacketPlant(packetConfig):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos)
        character.WeakUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt(purifyPacketName, gridPos.x, gridPos.y, _sync_id)
    Destroy()
