@tool
extends TowerDefenseZombie

const CARI_EXPLOSION = preload("uid://ch2ysy2khufj4")

@onready var zamboniSmoke: GPUParticles2D = %ZamboniSmoke

@onready var fireComponent: FireComponent = %FireComponent
@onready var catapultComponent: CatapultComponent = %CatapultComponent

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    catapultComponent.explosionEffect = CARI_EXPLOSION

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
    catapultComponent.PhysicsProcess(delta)

func IdleEntered() -> void :
    super.IdleEntered()

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    catapultComponent.IdleProcessing(delta)

func IdleExited() -> void :
    super.IdleExited()

func FireEntered() -> void :
    catapultComponent.FireEntered()

@warning_ignore("unused_parameter")
func FireProcessing(delta: float) -> void :
    catapultComponent.FireProcessing(delta)

func FireExited() -> void :
    pass

func WalkEntered() -> void :
    catapultComponent.WalkEntered()

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    catapultComponent.WalkProcessing(delta)

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    catapultComponent.CreateDeathEffect()
    Destroy()

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    catapultComponent.OnDamagePoint(damangePointName)

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "fire":
            catapultComponent.OnFireAnimeEvent()
            CreateBoom()
            _UpdateProjectileVisual()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Bounce":
            catapultComponent.CreateDeathEffect()
        "Fire":
            catapultComponent.OnFireAnimeCompleted()

func _UpdateProjectileVisual() -> void :
    var current: int = catapultComponent.currentProjectileNum
    var num: int = catapultComponent.projectileNum
    if current <= 0:
        sprite.SetFliters(["balloon1", "balloon_bottom1", "balloon_string1", "balloon2", "balloon_bottom2", "balloon_string2", "balloon3", "balloon_bottom3", "balloon_string3", "balloon4", "balloon_bottom4", "balloon_string4", "Zombie_catapult_basketball", "Zombie_catapult_basketball2", "Zombie_catapult_basketball3", "Zombie_catapult_basketball4"], false)
    elif current < float(num) / 4 * 1:
        sprite.SetFliters(["balloon3", "balloon_bottom3", "balloon_string3", "Zombie_catapult_basketball3"], false)
    elif current < float(num) / 4 * 2:
        sprite.SetFliters(["balloon2", "balloon_bottom2", "balloon_string2", "Zombie_catapult_basketball2"], false)
    elif current <= float(num) / 4 * 3:
        sprite.SetFliters(["balloon1", "balloon_bottom1", "balloon_string1", "Zombie_catapult_basketball"], false)

func CreateBoom() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieBalloonBomb")
    var character = packetConfig.Create(Vector2(fireComponent.firePosMarker[0].global_position.x, global_position.y), gridPos, 0.0)
    characterNode.add_child(character)
    character.Walk.call_deferred()
    if instance.hypnoses:
        character.Hypnoses()
