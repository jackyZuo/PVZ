@tool
extends TowerDefenseZombie

const ZAMBONI_EXPLOSION = preload("uid://bbsti03vlotx6")
const ZOMBIE_CATAPULT_POLE = preload("uid://bj2f8bm3g56me")
const ZOMBIE_CATAPULT_POLE_DAMAGE = preload("uid://dwrc0oqx3bcv")

@onready var zamboniSmoke: GPUParticles2D = %ZamboniSmoke
@onready var iceCapMarker: Marker2D = %IceCapMarker
@onready var fireSlot: AdobeAnimateSlot = %FireSlot

@onready var fireComponent: FireComponent = %FireComponent
@onready var catapultComponent: CatapultComponent = %CatapultComponent

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    catapultComponent.explosionEffect = ZAMBONI_EXPLOSION

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
    TowerDefenseManager.SetIceCapPos(gridPos.y, iceCapMarker.global_position)

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
    match damangePointName:
        "DamagePoint2":
            catapultComponent.speed = 25.0
        "DamagePoint3":
            catapultComponent.speed = 20.0
            if is_instance_valid(zamboniSmoke):
                zamboniSmoke.visible = true

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
        "Fire":
            catapultComponent.OnFireAnimeCompleted()
        "Wheelie":
            catapultComponent.CreateDeathEffect()

func _UpdateProjectileVisual() -> void :
    var current: int = catapultComponent.currentProjectileNum
    var num: int = catapultComponent.projectileNum
    if current <= 0:
        sprite.SetReplace("Zombie_zambonipult_pole_withball.png", ZOMBIE_CATAPULT_POLE)
        sprite.SetReplace("Zombie_zambonipult_pole_damage_withball.png", ZOMBIE_CATAPULT_POLE_DAMAGE)
        sprite.SetFliters(["Zombie_catapult_basketball", "Zombie_catapult_basketball2", "Zombie_catapult_basketball3", "Zombie_catapult_basketball4"], false)
    elif current <= float(num) / 4 * 1:
        sprite.SetFliters(["Zombie_catapult_basketball3"], false)
    elif current < float(num) / 4 * 2:
        sprite.SetFliters(["Zombie_catapult_basketball2"], false)
    elif current < float(num) / 4 * 3:
        sprite.SetFliters(["Zombie_catapult_basketball"], false)
