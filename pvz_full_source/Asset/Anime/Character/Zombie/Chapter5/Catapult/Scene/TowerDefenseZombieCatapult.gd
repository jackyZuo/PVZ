@tool
extends TowerDefenseZombie

const CARI_EXPLOSION = preload("uid://ch2ysy2khufj4")

@onready var zamboniSmoke: GPUParticles2D = %ZamboniSmoke
@onready var fireSlot: AdobeAnimateSlot = %FireSlot

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
            var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(-400, 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
            _UpdateProjectileVisual()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Bounce":
            catapultComponent.CreateDeathEffect()
        "Fire":
            catapultComponent.OnFireAnimeCompleted()

func _UpdateProjectileVisual() -> void :
    var num: int = catapultComponent.projectileNum
    var current: int = catapultComponent.currentProjectileNum
    if current <= 0:
        sprite.SetFliters(["Zombie_catapult_basketball", "Zombie_catapult_basketball2", "Zombie_catapult_basketball3", "Zombie_catapult_basketball4"], false)
    elif current <= float(num) / 4 * 1:
        sprite.SetFliters(["Zombie_catapult_basketball3"], false)
    elif current < float(num) / 4 * 2:
        sprite.SetFliters(["Zombie_catapult_basketball2"], false)
    elif current < float(num) / 4 * 3:
        sprite.SetFliters(["Zombie_catapult_basketball"], false)
