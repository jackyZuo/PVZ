@tool
extends TowerDefenseZombie

const DIGGER_RISING_DIRT = preload("uid://bjev0ulao283j")

var speed: float = 50.0

var digOver: bool = false

var discardDownPos: float = 10000.0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if (Engine.get_physics_frames() + randFreshIndex) % 30 == 0 && !inWater:
        SetSpriteGroupShaderParameter("discardDownPos", discardDownPos)

func DigEntered() -> void :
    attackAnimeClip = "Eat2"
    dieAnimeClip = "Death2"
    dieWaterAnimeClip = "Death2"
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    sprite.SetAnimation("Dig", true, 0.0)

@warning_ignore("unused_parameter")
func DigProcessing(delta: float) -> void :
    shadowSprite.visible = false
    if attackComponent.CanAttack() && !nearDie && !sprite.pause && !digOver:
        state.send_event("ToUp")
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

func DigExited() -> void :
    instance.unUseBuffFlags = 0

func DrillEntered() -> void :
    attackAnimeClip = "Eat"
    dieAnimeClip = "Death"
    dieWaterAnimeClip = "Death"
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
    if !inWater:
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
    attackAnimeClip = "Eat"
    dieAnimeClip = "Death"
    dieWaterAnimeClip = "Death"
    sprite.SetAnimation("Land", false, 0.0)

@warning_ignore("unused_parameter")
func LandProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func LandExited() -> void :
    pass

func UpEntered() -> void :
    var viewport: Viewport = get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    discardDownPos = (vt * (spriteGroup.global_position + Vector2(0, 53))).y
    SetSpriteGroupShaderParameter("discardDownPos", discardDownPos)
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
    if !inWater:
        shadowSprite.visible = !invisible
    attackAnimeClip = "Eat2"
    dieAnimeClip = "Death2"
    dieWaterAnimeClip = "Death2"
    sprite.SetAnimation("Up", false, 0.0)
    SetSpriteGroupShaderParameter("discardDownPos", discardDownPos)
    await get_tree().create_timer(0.2, false).timeout
    sprite.SetAnimation(attackAnimeClip, true, 0.2)
    startAttack = false
    await get_tree().create_timer(0.1, false).timeout
    startAttack = true

func UpExited() -> void :
    discardDownPos = 10000.0
    SetSpriteGroupShaderParameter("discardDownPos", discardDownPos)

@warning_ignore("unused_parameter")
func UpProcessing(delta: float) -> void :
    if !nearDie && !die && !digOver && !sprite.pause && !attackComponent.CanAttack():
        await get_tree().create_timer(0.2, false).timeout
        if !nearDie && !die && !attackComponent.CanAttack():
            Walk()
    else:
        if startAttack && !nearDie && !sprite.pause && sprite.timeScale > 0 && useAttackDps:
            attackComponent.AttackDps(delta, config.attack)
    sprite.timeScale = timeScale * 2.0

func Walk() -> void :
    if die:
        state.send_event("ToDie")
        return
    if digOver:
        state.send_event("ToWalk")
    else:
        state.send_event("ToDig")

func DieEntered() -> void :
    if dieAnimeClip != "":
        _dieClipArray = dieAnimeClip.split("&", false)
    if dieWaterAnimeClip != "":
        _dieWaterClipArray = dieWaterAnimeClip.split("&", false)
    super.DieEntered()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Drill":
            state.send_event("ToLand")
        "Land":
            Walk()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Pick":
            await get_tree().physics_frame
            if !digOver && !nearDie && !die:
                digOver = true
                state.send_event("ToDrill")

func CreateEffect() -> void :
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(DIGGER_RISING_DIRT, gridPos)
    effect.global_position = shadowSprite.global_position - Vector2(15, 0)
    characterNode.add_child(effect)

@warning_ignore("unused_parameter")
func BlockDigger(target: TowerDefenseCharacter) -> void :
    digOver = true
    state.send_event("ToDrill")

func ExportVariantSave() -> Dictionary:
    var data = super.ExportVariantSave()
    data["speed"] = speed
    data["digOver"] = digOver
    data["discardDownPos"] = discardDownPos
    return data

func ImportVariantSave(data: Dictionary) -> void :
    super.ImportVariantSave(data)
    speed = data.get("speed", 50.0)
    digOver = data.get("digOver", false)
    discardDownPos = data.get("discardDownPos", 10000.0)
