@tool
extends TowerDefenseZombie

@export var packetBank: String

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

var halfHp: bool = false
var isAttack: bool = false

var over: bool = false

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
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    super.ArmorDamagePointReach(armorName, stage)
    if isAttack && HasShield() && stage > 0:
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

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
    var packetBankData: TowerDefensePacketBankData
    if packetBank == "ZombiePresentBox":
        packetBankData = TowerDefenseManager.GetPacketBankData(packetBank if randf() > 0.01 else "EliteZombie")
    else:
        packetBankData = TowerDefenseManager.GetPacketBankData(packetBank)
    if is_instance_valid(packetBankData):
        var zombieList: Array = packetBankData.GetZombieList()
        var zombieRandom: String = zombieList.pick_random()
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombieRandom)
        while (instance.hypnoses && (packetConfig.characterConfig.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES)) && zombieList.size() > 1:
            zombieList.erase(zombieRandom)
            zombieRandom = zombieList.pick_random()
            packetConfig = TowerDefenseManager.GetPacketConfig(zombieRandom)
        if zombieList.size() > 1:
            if is_instance_valid(packetConfig):
                var zombie = packetConfig.Plant(gridPos, true)
                zombie.global_position = Vector2(global_position.x, TowerDefenseManager.GetMapCellPlantPos(gridPos).y)
                var _hitpointScale: float = instance.hitpointScale
                var _scale: Vector2 = transformPoint.scale
                ( func():
                    if is_instance_valid(zombie):
                        if is_instance_valid(zombie.instance):
                            zombie.instance.hitpointScale = _hitpointScale
                        if is_instance_valid(zombie.transformPoint):
                            zombie.transformPoint.scale = _scale).call_deferred()
                if instance.hypnoses:
                    zombie.Hypnoses(-1, false)

                if is_instance_valid(TowerDefenseBattleFeatureWave.instance):
                    TowerDefenseBattleFeatureWave.instance.currentHpPointTotal += zombie.GetTotalHitPoint() / 3
                    TowerDefenseBattleFeatureWave.instance.currentHpPoint += zombie.GetTotalHitPoint() / 3

                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt(zombieRandom, gridPos.x, gridPos.y, _sync_id, _hitpointScale, _scale.x, instance.hypnoses)

    Destroy.call_deferred()

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPresentBox")
    if cell.CanPacketPlant(packetConfig):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos)
        character.WakeUp.call_deferred()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantPresentBox", gridPos.x, gridPos.y, _sync_id)
    Destroy()
