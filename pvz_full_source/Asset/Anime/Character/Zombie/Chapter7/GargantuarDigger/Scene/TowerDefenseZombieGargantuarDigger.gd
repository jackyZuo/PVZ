@tool
extends TowerDefenseZombieGargantuarBase

const ZOMBIE_GARGANTUAR_HEAD_2 = preload("uid://cfx6iqy08xujv")

const DIGGER_RISING_DIRT = preload("uid://bjev0ulao283j")

var speed: float = 50.0

var digOver: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    useAttackDps = true

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            sprite.SetReplace("Zombie_gargantuar_head.png", ZOMBIE_GARGANTUAR_HEAD_2)
        impThrowDamagePointName:
            var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
            if mapFeature:
                if global_position.x < mapFeature.config.edge.x + TowerDefenseManager.GetMapGridSize().x * 5.0:
                    impThrowFlag = true

func DigEntered() -> void :
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    useAttackDps = true
    sprite.SetAnimation("Dig", true, 0.0)

@warning_ignore("unused_parameter")
func DigProcessing(delta: float) -> void :
    shadowSprite.visible = false
    if attackComponent.CanAttack():
        if !nearDie && !sprite.pause && sprite.timeScale > 0 && useAttackDps:
            if is_instance_valid(attackComponent.target):
                if attackComponent.target.instance.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND:
                    attackComponent.AttackDps(delta, config.attack)
                else:
                    attackComponent.target = null
    elif !sprite.pause:
        if global_position.x > TowerDefenseManager.GetMapGroundRight():
            global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * 2.0 * (-1 if sprite.playBack else 1)
        else:
            global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * (-1 if sprite.playBack else 1)
    sprite.timeScale = timeScale * 1.0

    if !digOver:
        if global_position.x < TowerDefenseManager.GetMapGroundLeft() + 30:
            digOver = true
            state.send_event("ToDrill")
            instance.ArmorDelete("Pick")
            if !instance.hypnoses:
                scale.x = - scale.x

func DigExited() -> void :
    instance.unUseBuffFlags = 0

func DrillEntered() -> void :
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
    useAttackDps = false
    shadowSprite.visible = !invisible
    CreateEffect()
    Rise(0.5, 0.0, false, false)
    sprite.SetAnimation("Drill", true, 0.2)

@warning_ignore("unused_parameter")
func DrillProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func DrillExited() -> void :
    pass

func LandEntered() -> void :
    sprite.SetAnimation("Land", false, 0.0)
    sprite.AddAnimation("Dizzy", 0.0, false, 0.2)

@warning_ignore("unused_parameter")
func LandProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func LandExited() -> void :
    pass

func Walk() -> void :
    if digOver:
        state.send_event("ToWalk")
    else:
        state.send_event("ToDig")

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Drill":
            state.send_event("ToLand")
        "Dizzy":
            Walk()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Pick":
            if !digOver:
                digOver = true
                state.send_event("ToDrill")

func CreateEffect() -> void :
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(DIGGER_RISING_DIRT, gridPos)
    effect.global_position = shadowSprite.global_position - Vector2(15, 0)
    characterNode.add_child(effect)

func ImpSpawn():
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    impSpawnSlot.Update()
    var impConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(impName)
    var height: float = GetGroundHeight(impSpawnSlot.global_position.y) - groundHeight
    var imp: TowerDefenseZombieImpBase = impConfig.Create(Vector2(impSpawnSlot.global_position.x, global_position.y), gridPos, height) as TowerDefenseZombieImpBase
    imp.ySpeed = -60.0
    imp.throw = true
    if sign(scale.x) < 0:
        imp.digOver = true
    imp.scale.x = scale.x
    characterNode.add_child(imp)
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    ( func():
        if is_instance_valid(imp):
            if is_instance_valid(imp.instance):
                imp.instance.hitpointScale = _hitpointScale
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

@warning_ignore("unused_parameter")
func BlockDigger(target: TowerDefenseCharacter) -> void :
    digOver = true
    state.send_event("ToDrill")

func ExportVariantSave() -> Dictionary:
    var data = super.ExportVariantSave()
    data["speed"] = speed
    data["digOver"] = digOver
    return data

func ImportVariantSave(data: Dictionary) -> void :
    super.ImportVariantSave(data)
    speed = data.get("speed", 50.0)
    digOver = data.get("digOver", false)
