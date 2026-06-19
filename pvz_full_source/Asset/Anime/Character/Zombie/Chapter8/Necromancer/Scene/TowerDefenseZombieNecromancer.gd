@tool
extends TowerDefenseZombie

@export var spawnTime: float = 10.0
var spawnTimer: float = 0.0
var over: bool = false

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
    AudioManager.AudioPlay("Skeleton", AudioManagerEnum.TYPE.SFX)
    sprite.SetAnimation("Spawn", true, 0.2)
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    SpawnPlantZombie(global_position - Vector2(gridSize.x * 1.25, 0))
    SpawnPlantZombie(global_position - Vector2(gridSize.x * 1.25 + 20, 0))

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

func SpawnPlantZombie(pos: Vector2i) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var zombie = CreateCharacter("ZombieSkeleton", pos, gridPos - Vector2i(1, 0), 0.0)
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
            MultiPlayerManager.SendSpawnCharacterAt("ZombieSkeleton", (gridPos - Vector2i(1, 0)).x, (gridPos - Vector2i(1, 0)).y, _sync_id, _hitpointScale, _scale.x, instance.hypnoses, 2.5, true, pos.x, pos.y)

func DestroySet() -> void :
    if inWater:
        return
    if over:
        return
    over = true
    CraterCreate(true, "CraterN")
    await get_tree().physics_frame

func ExportVariantSave() -> Dictionary:
    return {
        "spawnTimer": spawnTimer, 
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    spawnTimer = data.get("spawnTimer", 0.0)
    over = data.get("over", false)
