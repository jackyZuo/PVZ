@tool
extends TowerDefenseZombie






const SHOOT_INTERVAL: float = 8.0
const SPIKE_BALL_FALL_TIME: float = 0.6
const IMITATER_CLOUD: PackedScene = preload("uid://djvfnrjg7vtqn")
const CLOUD_SPRITE: PackedScene = preload("uid://csds4e7ibk87a")
const ARM_BONE_TEXTURE: Texture2D = preload("uid://bdvdk4frcvxu7")

var speed: float = 30.0
var _shootTimer: Timer
var _isShooting: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    _StartShootTimer()



func FlyEntered() -> void :

    sprite.SetAnimation("Idle", true, 0.2)
    if is_instance_valid(get_tree()):
        await get_tree().create_timer(0.1, false).timeout

func FlyProcessing(delta: float) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    sprite.timeScale = timeScale

    if !sprite.pause and !_isShooting:
        global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x

    if global_position.x < TowerDefenseManager.GetMapGroundLeft() + 20:
        Destroy()
        return

    if !sprite.pause and !_isShooting and attackComponent.CanAttack():
        state.send_event("ToFlyAttack")

func FlyExited() -> void :
    pass





func FlyAttackEntered() -> void :

    sprite.SetAnimation("Eat", true, 0.2)
    startAttack = false
    await get_tree().create_timer(0.1, false).timeout
    startAttack = true

func FlyAttackProcessing(delta: float) -> void :
    if !attackComponent.CanAttack():
        state.send_event("ToFly")
    else:
        if startAttack and !nearDie and !sprite.pause and sprite.timeScale > 0 and useAttackDps:
            attackComponent.AttackDps(delta, config.attack)
    sprite.timeScale = timeScale * 2.0

func FlyAttackExited() -> void :
    pass





func Walk() -> void :
    state.send_event("ToFly")

func Attack() -> void :
    state.send_event("ToFlyAttack")





func _StartShootTimer() -> void :
    _shootTimer = Timer.new()
    _shootTimer.wait_time = SHOOT_INTERVAL
    _shootTimer.one_shot = false
    _shootTimer.timeout.connect(_OnShootTimer)
    add_child(_shootTimer)
    _shootTimer.start()

func _OnShootTimer() -> void :
    if die or nearDie or _isShooting:
        return

    if attackComponent.CanAttack():
        return
    _isShooting = true
    sprite.SetAnimation("Shooting", false, 0.2)

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "fire":
            _ThrowSpikeBall()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Shooting":
            _isShooting = false
            if !die:
                Walk()


func _ThrowSpikeBall() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return

    var ballIndex: int = sprite.flashAnimeData.mediaDictionary.get(&"Zombie_cloud_ball.png", -1)
    if ballIndex < 0 or ballIndex >= sprite.flashAnimeData.mediaList.size():
        return
    var ballTexture: AtlasTexture = AtlasTexture.new()
    ballTexture.atlas = sprite.flashAnimeData.imageAtlas
    ballTexture.region = sprite.flashAnimeData.mediaList[ballIndex]

    var ball: Sprite2D = Sprite2D.new()
    ball.texture = ballTexture
    ball.global_position = sprite.global_position + Vector2(0, -20)
    TowerDefenseGroundItemBase.characterNode.add_child(ball)

    var groundY: float = TowerDefenseManager.GetMapCellPlantPos(gridPos).y

    var tween: Tween = create_tween()
    tween.tween_property(ball, ^"global_position:y", groundY, SPIKE_BALL_FALL_TIME)
    tween.tween_callback(_OnSpikeBallLanded.bind(ball))


func _OnSpikeBallLanded(ball: Sprite2D) -> void :
    var landPos: Vector2 = ball.global_position
    var landGridPos: Vector2i = TowerDefenseManager.GetMapGridPos(landPos)
    ball.queue_free()

    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, landGridPos)
    effect.global_position = landPos
    TowerDefenseGroundItemBase.characterNode.add_child(effect)

    var impConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieImpDiggerSpike")
    if is_instance_valid(impConfig):
        var imp = impConfig.Plant(landGridPos, true)
        if is_instance_valid(imp):
            imp.global_position = landPos





func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":

            sprite.SetFliter("lower2", false)

            sprite.SetReplace(&"Zombie_cloud_arm1.png", ARM_BONE_TEXTURE)





func DieEntered() -> void :
    super.DieEntered()

    _CreateFleeingCloud()
    _HideCloudLayers()


func _HideCloudLayers() -> void :
    sprite.SetFliters(["front"], false)


func _CreateFleeingCloud() -> void :
    if Engine.is_editor_hint():
        return

    var cloud = CLOUD_SPRITE.instantiate()
    TowerDefenseGroundItemBase.characterNode.add_child(cloud)
    cloud.global_position = sprite.global_position
    cloud.scale = transformPoint.scale * scale

    if cloud is AdobeAnimateSpriteBase:
        cloud.SetAnimation("Flee", true, 0.2)

        cloud.SetFliters([
            &"Zombie_imp_innerarm_upper", &"Zombie_imp_innerarm_lower", 
            &"Zombie_imp_innerleg_foot", &"Zombie_imp_innerleg_lower", 
            &"Zombie_imp_innerleg_upper", &"Zombie_imp_body2", &"Zombie_imp_body1", 
            &"Zombie_imp_outerleg_foot", &"Zombie_imp_outerleg_lower", 
            &"Zombie_imp_outerleg_upper", &"Zombie_imp_outerarm_upper", 
            &"Zombie_outerarm_lower", &"anim_head1", &"anim_head2", 
            &"glasses", &"ball", &"ball2", 
            &"spike1", &"spike2", &"spike3", &"spike4", &"spike5", 
            &"spike6", &"spike7", &"spike8", &"spike9"
        ], false)


    var tween: Tween = get_tree().create_tween()

    var direction: float = 1.0 if randf() > 0.5 else -1.0
    var targetX: float
    if direction > 0:
        targetX = TowerDefenseManager.GetMapGroundRight() + 200.0
    else:
        targetX = TowerDefenseManager.GetMapGroundLeft() - 200.0
    var targetY: float = cloud.global_position.y - 500.0
    var duration: float = 2.5
    tween.set_parallel(true)
    tween.tween_property(cloud, ^"global_position:x", targetX, duration).set_ease(Tween.EASE_IN)
    tween.tween_property(cloud, ^"global_position:y", targetY, duration).set_ease(Tween.EASE_IN)
    tween.chain().tween_callback(cloud.queue_free)



func ExportVariantSave() -> Dictionary:
    return {
        "speed": speed, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    speed = data.get("speed", 30.0)

func _notification(what: int) -> void :
    if what == NOTIFICATION_PREDELETE:
        if is_instance_valid(_shootTimer):
            _shootTimer.queue_free()
