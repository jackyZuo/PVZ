@tool
extends TowerDefenseZombieGargantuarBase

const ZOMBIE_GARGANTUAR_HEAD_2 = preload("uid://cfx6iqy08xujv")

const ZOMBIE_GARGANTUAR_DUCKXING = preload("uid://6dy81rx4gaue")
const ZOMBIE_GARGANTUAR_ZOMBIE = preload("uid://dtrl03qm2d0u7")

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

@export var packetBank: String
var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    var randWeapon = randf()
    if randWeapon < 0.3:
        sprite.SetReplace("Zombie_gargantuar_telephonepole.png", ZOMBIE_GARGANTUAR_DUCKXING)
    elif randWeapon < 0.6:
        sprite.SetReplace("Zombie_gargantuar_telephonepole.png", ZOMBIE_GARGANTUAR_ZOMBIE)

    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliter("Zombie_duckytube", true)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            sprite.SetReplace("Zombie_gargantuar_head.png", ZOMBIE_GARGANTUAR_HEAD_2)

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        impFireEvent:
            sprite.presentBoxImpHead.visible = false

func InWater() -> void :
    super.InWater()
    sprite.SetFliter("Zombie_whitewater", true)

func OutWater() -> void :
    super.OutWater()
    sprite.SetFliter("Zombie_whitewater", false)

func HitpointsNearDie() -> void :
    super.HitpointsNearDie()
    CreateRandom()

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    CreateRandom()

func CreateRandom() -> void :
    if over:
        return
    over = true

    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy.call_deferred()
        return

    await get_tree().physics_frame
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
    var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData(packetBank)
    if is_instance_valid(packetBankData):
        var zombieList: Array = packetBankData.GetZombieList()
        var zombieRandom: String = zombieList.pick_random()
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombieRandom)
        if is_instance_valid(packetConfig):
            var zombie = packetConfig.Plant(gridPos, true)
            zombie.global_position = Vector2(global_position.x, TowerDefenseManager.GetMapCellPlantPos(gridPos).y)
            zombie.instance.hitpointScale = instance.hitpointScale * 2.0
            zombie.transformPoint.scale = transformPoint.scale * 1.5
            if instance.hypnoses:
                zombie.Hypnoses()
            if is_instance_valid(TowerDefenseBattleProcessWave.instance):
                TowerDefenseBattleProcessWave.instance.currentHpPointTotal += zombie.GetTotalHitPoint() / 3
                TowerDefenseBattleProcessWave.instance.currentHpPoint += zombie.GetTotalHitPoint() / 3
            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                var control = TowerDefenseManager.currentControl
                if is_instance_valid(control):
                    var _sync_id: int = control._get_next_sync_id()
                    control._register_sync_character(_sync_id, zombie)
                    MultiPlayerManager.SendSpawnCharacterAt(zombieRandom, gridPos.x, gridPos.y, _sync_id, instance.hitpointScale * 2.0, transformPoint.scale.x * 1.5, instance.hypnoses)
    Destroy.call_deferred()
