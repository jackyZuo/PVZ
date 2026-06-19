@tool
extends TowerDefenseZombie

const CARI_EXPLOSION = preload("uid://ch2ysy2khufj4")
const ZOMBIE_IMPPULT_POLE = preload("uid://cca4mihbfcaul")
const ZOMBIE_IMPPULT_POLE_DAMAGE = preload("uid://d4n3vi3vviysr")

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
            ImpSpawn()
            _UpdateProjectileVisual()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Bounce":
            catapultComponent.CreateDeathEffect()
        "Fire":
            catapultComponent.OnFireAnimeCompleted()
            _UpdateProjectileVisualDelayed()

func _UpdateProjectileVisual() -> void :
    var current: int = catapultComponent.currentProjectileNum

    if current <= 0:
        sprite.SetReplace("Zombie_imppult_pole_withball.png", ZOMBIE_IMPPULT_POLE)
        sprite.SetReplace("Zombie_imppult_pole_damage_withball.png", ZOMBIE_IMPPULT_POLE_DAMAGE)
        sprite.SetFliters(["Zombie_catapult_basketball", "Zombie_catapult_basketball2", "Zombie_catapult_basketball3", "Zombie_catapult_basketball4", "Zombie_imp_outerarm_lower", "Zombie_imp_outerarm_upper", "Zombie_imp_innerarm_lower", "Zombie_imp_jaw", "Zombie_imp_head", "Zombie_imp_body1", "Zombie_imp_innerarm_upper"], false)

func _UpdateProjectileVisualDelayed() -> void :
    var current: int = catapultComponent.currentProjectileNum
    var num: int = catapultComponent.projectileNum
    if current < float(num) / 4 * 2:
        sprite.SetFliters(["Zombie_catapult_basketball3"], false)
    elif current < float(num) / 4 * 3:
        sprite.SetFliters(["Zombie_catapult_basketball2"], false)
    elif current < float(num) / 4 * 4:
        sprite.SetFliters(["Zombie_catapult_basketball"], false)

func ImpSpawn():
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    fireSlot.Update()
    await get_tree().physics_frame
    var impConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieImp")
    var height: float = GetGroundHeight(fireComponent.firePosMarker[0].global_position.y) - groundHeight - 70
    var imp: TowerDefenseZombieImpBase = impConfig.Create(Vector2(fireComponent.firePosMarker[0].global_position.x, global_position.y), gridPos, height) as TowerDefenseZombieImpBase
    imp.ySpeed = -240.0
    imp.throw = true
    characterNode.add_child(imp)
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    ( func():
        if is_instance_valid(imp):
            if is_instance_valid(imp.instance):
                imp.instance.hitpointScale = _hitpointScale
                if TowerDefenseManager.IsIZMMode():
                    imp.instance.hitpointScale = imp.instance.hitpointScale * 140.0 / 270.0
            if is_instance_valid(imp.transformPoint):
                imp.transformPoint.scale = _scale).call_deferred()
    imp.set_deferred("invisible", invisible)
    if instance.hypnoses:
        imp.Hypnoses()
    var landPosX: float = randf_range(TowerDefenseManager.GetMapCellPos(Vector2(3, 0)).x, TowerDefenseManager.GetMapCellPos(Vector2(5, 0)).x)
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(imp, "global_position:x", landPosX, imp.GetFallTime())
