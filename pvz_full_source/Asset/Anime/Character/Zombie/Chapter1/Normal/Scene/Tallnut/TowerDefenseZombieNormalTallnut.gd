@tool
extends TowerDefenseZombie

const TALLNUT_BODY = preload("uid://qbjvwqkpwidk")
const TALLNUT_CRACKED_1 = preload("uid://dee1e8301nnml")
const TALLNUT_CRACKED_2 = preload("uid://bquho427gnpsv")

var halfHp: bool = false
var isAttack: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

func AttackEntered() -> void :
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
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))
        "Damage1":
            sprite.head.SetReplace("Tallnut_body.png", TALLNUT_CRACKED_1)
        "Damage2":
            sprite.head.SetReplace("Tallnut_body.png", TALLNUT_CRACKED_2)

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
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantTallnut")
    if cell.CanPacketPlant(packetConfig):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos)
        character.WakeUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantTallnut", gridPos.x, gridPos.y, _sync_id)
    Destroy()
