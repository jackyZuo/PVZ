@tool
extends TowerDefenseZombie

const FIRE_BALL = preload("uid://ulproewvrqwb")
const ICE_BALL = preload("uid://calwfqgd47fn7")
const EXPLOSION = preload("uid://c8xarvk5gxpf0")

@onready var attackComponent1: AttackComponent = %AttackComponent1
@onready var attackComponent2: AttackComponent = %AttackComponent2
@onready var attackComponent3: AttackComponent = %AttackComponent3
@onready var attackComponent4: AttackComponent = %AttackComponent4
@onready var stompArea1: Area2D = %StompArea1
@onready var stompArea2: Area2D = %StompArea2
@onready var stompArea3: Area2D = %StompArea3
@onready var stompArea4: Area2D = %StompArea4
@onready var stompCollisionShape1: CollisionShape2D = %StompCollisionShape1
@onready var stompCollisionShape2: CollisionShape2D = %StompCollisionShape2
@onready var stompCollisionShape3: CollisionShape2D = %StompCollisionShape3
@onready var stompCollisionShape4: CollisionShape2D = %StompCollisionShape4
@onready var attackComponent5: AttackComponent = %AttackComponent5
@onready var rvArea5: Area2D = %RVArea5
@onready var rvCollisionShape5: CollisionShape2D = %RVCollisionShape5

var stageSpawnList = [
    [
        ["ZombieNormal"], 
        ["ZombieNormalCone"], 
        ["ZombieNormalBucket"], 
        ["ZombieNormalScreendoor", "ZombiePolevaulter", "ZombieSleeper", "ZombieFootball", "ZombieJackbox", "ZombiePogo", "ZombieLadder", "ZombieGargantuar", "ZombieZamboni", "ZombieCatapult"]
    ], 
    [
        ["ZombieNormalScreendoor", "ZombiePolevaulter", "ZombieSleeper", "ZombieFootball", "ZombieJackbox", "ZombiePogo", "ZombieLadder", "ZombieGargantuar", "ZombieZamboni", "ZombieCatapult"]
    ], 
    [
        ["ZombieNormalScreendoor", "ZombiePolevaulter", "ZombieSleeper", "ZombieFootball", "ZombieJackbox", "ZombiePogo", "ZombieLadder", "ZombieGargantuar", "ZombieZamboni", "ZombieCatapult"]
    ], 
    [
        ["ZombieNormalScreendoor", "ZombiePolevaulter", "ZombieSleeper", "ZombieFootball", "ZombieJackbox", "ZombiePogo", "ZombieLadder", "ZombieGargantuar", "ZombieZamboni", "ZombieCatapult"]
    ]
]

var stateMethodList: Array = []

var useEnterAnime: bool = true

var stateNow: String = ""
var spawnZombieNumOnce: int = 5
var spawnZombieNumNow: int = 0
var spawnTime: float = 5
var spawnLine: int = 1
var spawnRestTime: float = 4.0
var spawnRestTimer: float = 0.0
var spawnZomie: String
var spawnNum: int = 0

var headAttackOver: bool = false
var headAttackLine: int = 1
var headAttackIsFire: bool = true
var headAttackRestTime: float = 10.0
var headAttackRestTimer: float = 0.0

var bungeeIsSpawn: bool = false
var bungeeList: Array

var stompId: int = -1

var rvPos: Vector2i

var isRest: bool = true
var restTime: float = 5.0
var restTimer: float = 0.0

var headIdleNum: int = 0

var stage: int = 0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if !inGame:
        return
    var collisionShapeSize = TowerDefenseManager.GetMapGridSize() * Vector2(float(TowerDefenseManager.GetMapGridNum().x) / 2, TowerDefenseManager.GetMapGridNum().y) / Vector2(1, 2.5)
    stompCollisionShape1.shape.size = collisionShapeSize
    stompCollisionShape2.shape.size = collisionShapeSize
    stompCollisionShape3.shape.size = collisionShapeSize
    stompCollisionShape4.shape.size = collisionShapeSize
    rvCollisionShape5.shape.size = TowerDefenseManager.GetMapGridSize() * Vector2(3, 2)
    var collisionShapeOffset = TowerDefenseManager.GetMapGridSize() * Vector2(float(TowerDefenseManager.GetMapGridNum().x) / 2, TowerDefenseManager.GetMapGridNum().y) / Vector2(1, 4)
    stompArea1.position.y = - collisionShapeOffset.y * 1.5
    stompArea2.position.y = - collisionShapeOffset.y * 0.5
    stompArea3.position.y = collisionShapeOffset.y * 0.5
    stompArea4.position.y = collisionShapeOffset.y * 1.5
    stompArea1.position.x = -100
    stompArea2.position.x = -100
    stompArea3.position.x = -100
    stompArea4.position.x = -100
    gridPos = Vector2(TowerDefenseManager.GetMapGridNum().x, floor(float(TowerDefenseManager.GetMapGridNum().y) / 2) + 1)
    global_position = TowerDefenseManager.GetMapCellPlantPos(gridPos)
    SetStateList()
    instance.invincible = true
    instance.canBeCollection = false
    targetRegistrationComponent.allLineCheck = false
    targetRegistrationComponent.canProjectileCheck = false
    instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL
    await get_tree().physics_frame
    useEnterAnime = true

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !inGame:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if Engine.get_physics_frames() % 5 == 0:
        SetSpriteGroupShaderParameter("discardDownPos", 10000.0)

    if isRest:
        if restTimer < restTime:
            restTimer += delta
        else:
            restTimer = 0.0
            stateNow = stateMethodList.pop_front()
            isRest = false
            if stateNow != "HeadIdle":
                if stateMethodList.is_empty():
                    stateMethodList.append("HeadIdle")

func Walk() -> void :
    Idle()

func HeadIdleEntered() -> void :
    AudioManager.AudioPlay("HydraulicShort", AudioManagerEnum.TYPE.SFX)
    AudioManager.AudioPlay("Hydraulic", AudioManagerEnum.TYPE.SFX)
    headAttackRestTimer = 0.0
    if !headAttackOver:
        sprite.SetAnimation("HeadEnter", false, 0.2)
        sprite.AddAnimation("HeadIdle", 0.0, true)
    else:
        sprite.SetAnimation("HeadIdle", true, 0.2)

@warning_ignore("unused_parameter")
func HeadIdleProcessing(delta: float) -> void :
    z_index = 1000
    sprite.timeScale = timeScale * 1.0
    if !sprite.pause:
        if headAttackRestTimer < headAttackRestTime:
            headAttackRestTimer += delta * timeScale
        else:
            headAttackRestTimer = 0.0
            if !headAttackOver:
                state.send_event("ToHeadAttack")
            else:
                state.send_event("ToHeadExited")

func HeadIdleExited() -> void :
    pass

func HeadAttackEntered() -> void :
    headAttackOver = true
    headAttackLine = randi_range(1, TowerDefenseManager.GetMapGridNum().y)
    headAttackIsFire = randf() > 0.5
    z_index = 0 + headAttackLine * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + itemLayer
    sprite.SetHeadAttack(headAttackLine, 1.0)
    sprite.SetHeadAttackBall(headAttackIsFire)
    sprite.SetAnimation("HeadAttack4", false, 0.2)

@warning_ignore("unused_parameter")
func HeadAttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func HeadAttackExited() -> void :
    pass

func HeadExitedEntered() -> void :
    instance.invincible = true
    instance.canBeCollection = false
    targetRegistrationComponent.canProjectileCheck = false
    instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL
    targetRegistrationComponent.allLineCheck = false
    if buff.BuffHas("Frozen"):
        buff.BuffDelete("Frozen")
    if buff.BuffHas("IceSpeedDown"):
        buff.BuffDelete("IceSpeedDown")
    sprite.SetAnimation("HeadExited", false, 0.0)

@warning_ignore("unused_parameter")
func HeadExitedProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func HeadExitedExited() -> void :
    pass

func SpawnEntered() -> void :
    AudioManager.AudioPlay("HydraulicShort", AudioManagerEnum.TYPE.SFX)
    spawnZomie = GetSpawnZombie()
    spawnLine = randi_range(1, TowerDefenseManager.GetMapGridNum().y)
    sprite.SetAnimation("Spawn1", false, 0.2)
    sprite.SetSpawn(spawnLine)

@warning_ignore("unused_parameter")
func SpawnProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func SpawnExited() -> void :
    pass

func StompEntered() -> void :
    AudioManager.AudioPlay("HydraulicShort", AudioManagerEnum.TYPE.SFX)
    var canStompList: Array[int] = []
    if attackComponent1.CanAttackOnce():
        canStompList.append(1)
    if attackComponent2.CanAttackOnce():
        canStompList.append(2)
    if attackComponent3.CanAttackOnce():
        canStompList.append(3)
    if attackComponent4.CanAttackOnce():
        canStompList.append(4)
    if canStompList.size() > 0:
        stompId = canStompList.pick_random()
    else:
        stompId = 3
    match stompId:
        1:
            sprite.SetAnimation("Stomp1", false, 0.2)
        2:
            sprite.SetAnimation("Stomp2", false, 0.2)
        3:
            sprite.SetAnimation("Stomp3", false, 0.2)
        4:
            sprite.SetAnimation("Stomp4", false, 0.2)

@warning_ignore("unused_parameter")
func StompProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func StompExited() -> void :
    pass

func BungeeEntered() -> void :
    AudioManager.AudioPlay("HydraulicShort", AudioManagerEnum.TYPE.SFX)
    bungeeIsSpawn = false
    sprite.SetAnimation("BungeeEnter", false, 0.2)

@warning_ignore("unused_parameter")
func BungeeProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if bungeeIsSpawn:
        for bungee in bungeeList:
            if !is_instance_valid(bungee):
                bungeeList.erase(bungee)
                break
        if bungeeList.size() <= 0:
            sprite.SetAnimation("BungeeExited", false, 0.2)
            bungeeIsSpawn = false

func BungeeExited() -> void :
    pass

func RVEntered() -> void :
    AudioManager.AudioPlay("HydraulicShort", AudioManagerEnum.TYPE.SFX)
    rvPos = Vector2i(floor(float(TowerDefenseManager.GetMapGridNum().x) / 2 - 1), TowerDefenseManager.GetMapGridNum().y - 1)
    sprite.SetAnimation("RV", false, 0.2)

@warning_ignore("unused_parameter")
func RVProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func RVExited() -> void :
    pass

func IdleEntered() -> void :
    if !inGame:
        sprite.SetAnimation("HeadIdle", true)
        return
    instance.invincible = true
    instance.canBeCollection = false
    if useEnterAnime:
        sprite.SetAnimation("Enter", false, 0.2)
        sprite.AddAnimation("Idle", 0.0, true)
        useEnterAnime = false
    else:
        sprite.SetAnimation("Idle", true, 0.2)

func IdleProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    StateRunning(delta)

func DieEntered() -> void :
    var change: bool = false
    if sprite.clip == "HeadIdle" || sprite.clip == "HeadAttack4":
        change = true
    super.DieEntered()
    sprite.SetHeadAttack(floor(float(TowerDefenseManager.GetMapGridNum().y) / 2) + 2, 0.5)
    spritePause = false
    z_index = 0 + headAttackLine * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + itemLayer
    if change:
        sprite.SetAnimation("HeadExited", false, 0.2)
        sprite.AddAnimation("Death", 0.0, false)
    else:
        sprite.SetAnimation("Death", false, 0.2)

@warning_ignore("unused_parameter")
func DieProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 0.5

func DamagePointReach(damagePointName: String) -> void :
    super.DamagePointReach(damagePointName)
    sprite.DamagePointSet(damagePointName)
    match damagePointName:
        "Stage1":
            stage = 1
            restTime = 4.5
            spawnRestTime = 3.5
        "Stage2":
            stage = 2
            restTime = 4.0
            spawnRestTime = 3.0
        "Stage3":
            stage = 3
            Explosion()
        "Death":
            timeScaleInit = 3.0
            AudioManager.AudioPlay("Bossexplosion", AudioManagerEnum.TYPE.SFX)

func AnimeCompleted(clip: String) -> void :
    if dieAnimeClip.split("&", false).has(clip):
        remove_from_group("Zombie")
        return
    if die:
        HitBoxDestroy()
        Die()
    sprite.AnimeCompleted(clip)
    match clip:
        "Spawn1":
            if !die:
                Idle()
        "HeadEnter":
            instance.invincible = false
            instance.canBeCollection = true
            targetRegistrationComponent.canProjectileCheck = true
            targetRegistrationComponent.allLineCheck = true
            instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL - TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ICESPEEDDOWN - TowerDefenseEnum.CHARACTER_BUFF_FLAGS.FROZEN
        "HeadExited":
            FreshZIndex()
            SetStateList()
            isRest = true
            restTimer = 2.0
            if !die:
                Idle()
        "HeadAttack4":
            state.send_event("ToHeadIdle")
        "BungeeExited":
            FreshZIndex()
            isRest = true
            if !die:
                Idle()
        "Stomp1", "Stomp2", "Stomp3", "Stomp4":
            isRest = true
            if !die:
                Idle()
        "RV":
            isRest = true
            if !die:
                Idle()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "spawn":
            ZombieSpawn()
        "spawnBubgee":
            BungeeSpawn()
        "headAttack":
            BallSpawn()
            spritePause = true
            await get_tree().create_timer(1.0, false).timeout
            spritePause = false
            z_index = 0 + headAttackLine * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + itemLayer
        "headAttackOver":
            sprite.SetHeadAttack(floor(float(TowerDefenseManager.GetMapGridNum().y) / 2) + 2, 0.5)
        "stomp":
            AudioManager.AudioPlay("GargantuarThump", AudioManagerEnum.TYPE.SFX)
            match stompId:
                1:
                    attackComponent1.SmashAttackAll(100000.0)
                2:
                    attackComponent2.SmashAttackAll(100000.0)
                3:
                    attackComponent3.SmashAttackAll(100000.0)
                4:
                    attackComponent4.SmashAttackAll(100000.0)
        "throwRV":
            sprite.SetRVVisible(true)
            RVSpawn()
        "RVAttack":
            AudioManager.AudioPlay("RVThrow", AudioManagerEnum.TYPE.SFX)
            attackComponent5.SmashAttackAll(100000.0)
        "explode":
            Explosion()
        "footstep":
            AudioManager.AudioPlay("GargantuarThump", AudioManagerEnum.TYPE.SFX)

func StateRunning(delta: float) -> void :
    match stateNow:
        "Spawn":
            if spawnRestTimer < spawnRestTime:
                spawnRestTimer += delta
            else:
                state.send_event("ToSpawn")
                spawnZombieNumNow += 1
                spawnRestTimer = 0.0
                if spawnZombieNumNow >= spawnZombieNumOnce:
                    spawnNum += 1
                    spawnZombieNumNow = 0
                    isRest = true
                    stateNow = ""
        "HeadIdle":
            headAttackOver = false
            headIdleNum += 1
            state.send_event("ToHeadIdle")
            stateNow = ""
        "BungeeSpawn":
            state.send_event("ToBungee")
            stateNow = ""
        "Stomp":
            state.send_event("ToStomp")
            stateNow = ""
        "RV":
            state.send_event("ToRV")
            stateNow = ""

func ZombieSpawn() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(spawnZomie)
    var spawn_pos: Vector2 = Vector2(sprite.spawnMarker.global_position.x, TowerDefenseManager.GetMapCellPlantPos(Vector2(0, spawnLine)).y)
    var zombie: TowerDefenseCharacter = packetConfig.Create(spawn_pos, Vector2(100, spawnLine))
    characterNode.add_child(zombie)
    zombie.call_deferred("Walk")
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt(spawnZomie, 100, spawnLine, _sync_id, 1.0, 1.0, false, 0.0, true, spawn_pos.x, spawn_pos.y, true)

func BungeeSpawn() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var plantList = get_tree().get_nodes_in_group("Plant").filter(
        func(checkCharacter: TowerDefenseCharacter):
            return checkCharacter.gridPos.x <= floor(float(TowerDefenseManager.GetMapGridNum().x) / 2) + 1
    )
    var posList: Array[Vector2i] = []
    for character in plantList:
        if !posList.has(character.gridPos):
            posList.append(character.gridPos)
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieBungi")
    var bungee_spawn_positions: Array[Vector2i] = []
    for i in min(3, posList.size()):
        var pos = posList.pick_random()
        posList.erase(pos)
        bungee_spawn_positions.append(pos)
        var bungee = packetConfig.Plant(pos, false)
        bungee.skipBungeeTarget = true
        bungeeList.append(bungee)
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, bungee)
                MultiPlayerManager.SendSpawnCharacterAt("ZombieBungi", pos.x, pos.y, _sync_id)
    bungeeIsSpawn = true

func RVSpawn() -> void :
    var plantList = get_tree().get_nodes_in_group("Plant").filter(
        func(checkCharacter: TowerDefenseCharacter):
            return checkCharacter.gridPos.x <= floor(float(TowerDefenseManager.GetMapGridNum().x) / 2) - 1
    )
    var posList: Array[Vector2i] = []
    for character in plantList:
        if !posList.has(character.gridPos):
            posList.append(character.gridPos)
    var pos
    if posList.size() > 0:
        pos = posList.pick_random()
    else:
        pos = Vector2i(1, 2)
    if pos.y >= TowerDefenseManager.GetMapGridNum().y:
        pos.y -= 1
    rvPos = pos
    rvArea5.global_position = TowerDefenseManager.GetMapCellPos(rvPos) + TowerDefenseManager.GetMapGridSize() * Vector2(1.5, 1.0)
    sprite.SetRVPos(rvPos)

func BallSpawn() -> void :
    AudioManager.AudioPlay("Bossboulderattack", AudioManagerEnum.TYPE.SFX)
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig
    var effect: TowerDefenseEffectParticlesOnce

    var ball_pos: Vector2 = Vector2(sprite.ballSpawnMarker.global_position.x, TowerDefenseManager.GetMapCellPlantPos(Vector2(0, headAttackLine)).y)
    if headAttackIsFire:
        packetConfig = TowerDefenseManager.GetPacketConfig("ItemFireball")
        var ball = packetConfig.Create(ball_pos, Vector2(100, headAttackLine))
        characterNode.add_child(ball)
        effect = TowerDefenseManager.CreateEffectParticlesOnce(FIRE_BALL, Vector2(100, headAttackLine))
        characterNode.add_child(effect)
        effect.global_position = ball_pos
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, ball)
                MultiPlayerManager.SendSpawnCharacterAt("ItemFireball", 100, headAttackLine, _sync_id, 1.0, 1.0, false, 0.0, true, ball_pos.x, ball_pos.y)
    else:
        packetConfig = TowerDefenseManager.GetPacketConfig("ItemIceball")
        var ball = packetConfig.Create(ball_pos, Vector2(100, headAttackLine))
        characterNode.add_child(ball)
        effect = TowerDefenseManager.CreateEffectParticlesOnce(ICE_BALL, Vector2(100, headAttackLine))
        characterNode.add_child(effect)
        effect.global_position = ball_pos
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, ball)
                MultiPlayerManager.SendSpawnCharacterAt("ItemIceball", 100, headAttackLine, _sync_id, 1.0, 1.0, false, 0.0, true, ball_pos.x, ball_pos.y)

func GetSpawnZombie() -> String:
    var zombiePool: Array = []
    var spawnStage: Array
    if stage < stageSpawnList.size():
        spawnStage = stageSpawnList[stage]
    else:
        spawnStage = stageSpawnList[stageSpawnList.size() - 1]
    if spawnNum < spawnStage.size():
        zombiePool = spawnStage[spawnNum]
    else:
        zombiePool = spawnStage[spawnStage.size() - 1]
    return TowerDefenseManager.PickRandomZomie(zombiePool)

func SetStateList() -> void :
    match headIdleNum:
        0:
            stateMethodList = ["Spawn", "Spawn"]
        1:
            stateMethodList = ["Spawn"]
        _:
            stateMethodList = ["Spawn"]
    if stage > 1:
        if randf() > 0.25:
            stateMethodList.push_front("BungeeSpawn")
        else:
            stateMethodList.push_front("RV")
        if attackComponent1.CanAttackOnce() || attackComponent2.CanAttackOnce() || attackComponent3.CanAttackOnce() || attackComponent4.CanAttackOnce():
            stateMethodList.push_front("Stomp")

func Explosion() -> void :
    AudioManager.AudioPlay("ZamboniExplosion", AudioManagerEnum.TYPE.SFX)
    var effect: TowerDefenseEffectParticlesOnce
    effect = TowerDefenseManager.CreateEffectParticlesOnce(EXPLOSION, Vector2(100, 100))
    characterNode.add_child(effect)
    effect.position = position - Vector2(randf_range(-50, 50), randf_range(-100, 100))

func InWater() -> void :
    pass

func OutWater() -> void :
    pass

func InWaterDiscardSet() -> void :
    pass

func OutWaterDiscardSet() -> void :
    pass

func ExportVariantSave() -> Dictionary:
    return {
        "stage": stage, 
        "stateNow": stateNow, 
        "useEnterAnime": useEnterAnime, 
        "spawnZombieNumOnce": spawnZombieNumOnce, 
        "spawnZombieNumNow": spawnZombieNumNow, 
        "spawnTime": spawnTime, 
        "spawnLine": spawnLine, 
        "spawnRestTime": spawnRestTime, 
        "spawnRestTimer": spawnRestTimer, 
        "spawnZomie": spawnZomie, 
        "spawnNum": spawnNum, 
        "headAttackOver": headAttackOver, 
        "headAttackLine": headAttackLine, 
        "headAttackIsFire": headAttackIsFire, 
        "headAttackRestTime": headAttackRestTime, 
        "headAttackRestTimer": headAttackRestTimer, 
        "headIdleNum": headIdleNum, 
        "bungeeIsSpawn": bungeeIsSpawn, 
        "stompId": stompId, 
        "isRest": isRest, 
        "restTime": restTime, 
        "restTimer": restTimer, 
        "stateMethodList": stateMethodList, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    stage = data.get("stage", 0)
    stateNow = data.get("stateNow", "")
    useEnterAnime = data.get("useEnterAnime", true)
    spawnZombieNumOnce = data.get("spawnZombieNumOnce", 5)
    spawnZombieNumNow = data.get("spawnZombieNumNow", 0)
    spawnTime = data.get("spawnTime", 5)
    spawnLine = data.get("spawnLine", 1)
    spawnRestTime = data.get("spawnRestTime", 4.0)
    spawnRestTimer = data.get("spawnRestTimer", 0.0)
    spawnZomie = data.get("spawnZomie", "")
    spawnNum = data.get("spawnNum", 0)
    headAttackOver = data.get("headAttackOver", false)
    headAttackLine = data.get("headAttackLine", 1)
    headAttackIsFire = data.get("headAttackIsFire", true)
    headAttackRestTime = data.get("headAttackRestTime", 10.0)
    headAttackRestTimer = data.get("headAttackRestTimer", 0.0)
    headIdleNum = data.get("headIdleNum", 0)
    bungeeIsSpawn = data.get("bungeeIsSpawn", false)
    stompId = data.get("stompId", -1)
    isRest = data.get("isRest", true)
    restTime = data.get("restTime", 5.0)
    restTimer = data.get("restTimer", 0.0)
    stateMethodList = data.get("stateMethodList", [])
