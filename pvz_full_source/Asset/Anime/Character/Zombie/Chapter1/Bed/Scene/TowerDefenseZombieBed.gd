@tool
extends TowerDefenseZombie

var over: bool = false

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    if global_position.x > TowerDefenseManager.GetMapGroundRight():
        sprite.timeScale = timeScale * walkSpeedScale * 2.0
    else:
        sprite.timeScale = timeScale * walkSpeedScale

    if attackComponent.CanAttack():
        if is_instance_valid(attackComponent.target.cell):
            if attackComponent.target.cell.HasSpike():
                attackComponent.target = attackComponent.target.cell.GetSpike()
        if !attackComponent.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
            attackComponent.SmashAttackCell(config.smashAttack)
        else:
            if attackComponent.target.instance.spikeHurt != -1:
                attackComponent.target.Hurt(attackComponent.target.instance.spikeHurt)
            Die()

func DieEntered() -> void :
    super.DieEntered()
    DestroySet()

func DestroySet() -> void :
    if over:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        over = true
        return
    over = true
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieSleeper")
    var sleeper = packetConfig.Create(global_position + Vector2(45, 0), gridPos, 50)
    characterNode.add_child.call_deferred(sleeper)
    if instance.hypnoses:
        sleeper.Hypnoses.call_deferred()
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    ( func():
        if is_instance_valid(sleeper):
            if is_instance_valid(sleeper.instance):
                sleeper.instance.hitpointScale = _hitpointScale
            if is_instance_valid(sleeper.transformPoint):
                sleeper.transformPoint.scale = _scale).call_deferred()
    sleeper.set_deferred("invisible", invisible)
    var tween = sleeper.create_tween()
    tween.tween_property(sleeper, ^"rotation_degrees", 0, 0.2).from(90 * scale.x)
    get_tree().create_timer(0.1, false).timeout.connect(
        func():
            if is_instance_valid(sleeper):
                sleeper.Walk()
    )
    await get_tree().physics_frame
