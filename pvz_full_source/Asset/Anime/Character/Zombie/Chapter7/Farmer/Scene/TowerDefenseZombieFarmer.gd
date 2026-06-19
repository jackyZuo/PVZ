@tool
extends TowerDefenseZombie

@export var spawnList: Array[String] = ["ZombieNormalPeaShooterSingle", "ZombieNormalSnowPea", "ZombieNormalSunflower", "ZombieNormalWallnut"]
@export var spawnTime: float = 10.0
var spawnTimer: float = 0.0


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
    if !sprite.pause:
        if spawnTimer < spawnTime:
            spawnTimer += delta * timeScale
        else:
            state.send_event("ToSpawn")
            spawnTimer = 0.0

func SpawnEntered() -> void :
    sprite.SetAnimation("Spawn", true, 0.2)
    SpawnPlantZombie()

@warning_ignore("unused_parameter")
func SpawnProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.5

func SpawnExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Spawn":
            Walk()

func SpawnPlantZombie() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var spawn_name: String = spawnList.pick_random()
    var spawn_pos: Vector2 = global_position - Vector2(20 * scale.x, 0)
    var zombie = CreateCharacter(spawn_name, spawn_pos, gridPos, 0.0)
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    ( func():
        if is_instance_valid(zombie):
            if is_instance_valid(zombie.instance):
                zombie.instance.hitpointScale = _hitpointScale
            if is_instance_valid(zombie.transformPoint):
                zombie.transformPoint.scale = _scale).call_deferred()
    zombie.Rise(2.5)
    if instance.hypnoses:
        zombie.Hypnoses()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt(spawn_name, gridPos.x, gridPos.y, _sync_id, _hitpointScale, _scale.x, instance.hypnoses, 2.5, true, spawn_pos.x, spawn_pos.y)
