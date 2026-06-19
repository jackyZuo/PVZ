@tool
extends TowerDefenseZombie

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")


@export var spawnTime: float = 15.0
var spawnTimer: float = 0.0

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if die || nearDie:
        return
    if global_position.x > groundRight:
        return
    if !sprite.pause:
        if spawnTimer < spawnTime:
            spawnTimer += delta * timeScale
        else:
            state.send_event("ToSpawn")
            spawnTimer = 0.0

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 4.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func SpawnEntered() -> void :
    SpawnCrew()
    sprite.SetAnimation("Spawn", true, 0.2)

@warning_ignore("unused_parameter")
func SpawnProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func SpawnExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Spawn":
            Walk()

func HitpointsNearDie() -> void :
    super.HitpointsNearDie()
    DestroySet()

func SpawnCrew() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var spawwLineList: Array[int] = []
    for y in range(gridPos.y - 1, gridPos.y + 2, 1):
        if y >= 1 && y <= TowerDefenseManager.GetMapGridNum().y:
            spawwLineList.append(y)
    if spawwLineList.size() <= 0:
        return

    for i in 4:
        var posX = global_position.x + randf_range(-1.5, 1.5) * TowerDefenseManager.GetMapGridSize().x
        var characterOverride: TowerDefenseCharacterOverride = TowerDefenseCharacterOverride.new()
        characterOverride.hitpointScale = instance.hitpointScale
        characterOverride.scale = transformPoint.scale.x
        TowerDefenseManager.BungiSpawn("ZombieCrew", Vector2i(TowerDefenseManager.GetMapGridPos(Vector2(posX, 0)).x, spawwLineList.pick_random()), characterOverride, instance.hypnoses)

func DestroySet() -> void :
    super.DestroySet()
    if instance.hitpoints > 0:
        return
    if over:
        return
    over = true
    if TowerDefenseInGameLevelControl.instance.awardCreate:
        return
    if get_tree().get_node_count_in_group("ZombieCrew") <= 0:
        return
    var crewList = get_tree().get_nodes_in_group("ZombieCrew")
    var changeCrew: TowerDefenseCharacter = null
    for crew: TowerDefenseCharacter in crewList:
        if instance.hypnoses != crew.instance.hypnoses:
            continue
        if !is_instance_valid(changeCrew):
            changeCrew = crew
            continue
        if global_position.distance_squared_to(crew.global_position) < global_position.distance_squared_to(changeCrew.global_position):
            changeCrew = crew
    if is_instance_valid(changeCrew):
        if changeCrew.isDestroy:
            return
        if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
            changeCrew.Destroy()
            return
        var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, changeCrew.gridPos)
        effect.global_position = changeCrew.global_position
        characterNode.add_child(effect)
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieCaptain")
        var zombie = packetConfig.Create(changeCrew.global_position, changeCrew.gridPos, 0.0)
        characterNode.add_child(zombie)
        var _hitpointScale: float = instance.hitpointScale
        var _scale: Vector2 = transformPoint.scale
        ( func():
            if is_instance_valid(zombie):
                if is_instance_valid(zombie.instance):
                    zombie.instance.hitpointScale = _hitpointScale
                if is_instance_valid(zombie.transformPoint):
                    zombie.transformPoint.scale = _scale).call_deferred()
        zombie.Walk.call_deferred()
        if instance.hypnoses:
            zombie.Hypnoses.call_deferred()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, zombie)
                MultiPlayerManager.SendSpawnCharacterAt("ZombieCaptain", changeCrew.gridPos.x, changeCrew.gridPos.y, _sync_id, _hitpointScale, _scale.x, instance.hypnoses, 0.0, true, changeCrew.global_position.x, changeCrew.global_position.y, true)
        changeCrew.Destroy()
