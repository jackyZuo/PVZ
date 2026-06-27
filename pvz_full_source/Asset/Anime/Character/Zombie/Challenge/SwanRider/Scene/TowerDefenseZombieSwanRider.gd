@tool
extends TowerDefenseZombie

var useCone: bool = false
var useBucket: bool = false
var over: bool = false
var isFly: bool = false
var speed: float = 30.0
var isFlying: bool = false
var mowerKill: bool = false

var carryCharacter: TowerDefenseCharacter

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    var rand = randf()
    if rand < 0.1:
        useBucket = true
        sprite.SetFliters(["anim_bucket"], true)
    elif rand < 0.3:
        useCone = true
        sprite.SetFliters(["anim_cone"], true)
    targetRegistrationComponent.canCarry = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if over:
        return
    if die || nearDie:
        return
    if is_instance_valid(carryCharacter):
        if instance.hypnoses:
            carryCharacter.global_position.x = global_position.x - 30
        else:
            carryCharacter.global_position.x = global_position.x + 30
        carryCharacter.groundHeight = z + 60
        carryCharacter.z = z + 60

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
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
    if instance.hitpoints <= 1000 && !isFly:
        if inWater:
            sprite.SetAnimation("RiseWater", false, 0.2)
        else:
            sprite.SetAnimation("Rise", false, 0.2)
        isFly = true

func DieEntered() -> void :
    super.DieEntered()


func DestroySet() -> void :
    if over:
        return
    over = true
    HitBoxDestroy()
    sprite.SetFliters(["anim_bucket", "anim_cone", "anim_hair", "Zombie_outerarm_lower", "Zombie_outerarm_upper", "Zombie_outerarm_hand", "anim_head2", "Zombie_tie", "Zombie_body", "Zombie_outerleg_lower", "Zombie_outerleg_foot", "Zombie_outerleg_upper", "Zombie_innerleg_foot", "Zombie_innerleg_lower", "Zombie_innerleg_upper", "anim_head1", "Zombie_neck", "anim_innerarm1", "anim_innerarm2", "anim_innerarm3"], false)
    if is_instance_valid(carryCharacter):
        carryCharacter.isGround = false
        carryCharacter.groundHeight = groundHeight
        carryCharacter.isPause = false
        carryCharacter = null
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if mowerKill:
        await get_tree().physics_frame
        return
    var packetName: String = "ZombieNormal"
    if useCone:
        packetName = "ZombieNormalCone"
    if useBucket:
        packetName = "ZombieNormalBucket"
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
    var zombie = packetConfig.Create(global_position, gridPos, 40)
    characterNode.add_child.call_deferred(zombie)
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    ( func():
        if is_instance_valid(zombie):
            if is_instance_valid(zombie.instance):
                zombie.instance.hitpointScale = _hitpointScale
            if is_instance_valid(zombie.transformPoint):
                zombie.transformPoint.scale = _scale).call_deferred()
    if instance.hypnoses:
        zombie.Hypnoses.call_deferred()
    await get_tree().create_timer(0.1, false).timeout
    if is_instance_valid(zombie):
        zombie.Walk()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt(packetName, gridPos.x, gridPos.y, _sync_id, _hitpointScale, _scale.x, instance.hypnoses, 0.0, true, global_position.x, global_position.y, true, 40.0)
    await get_tree().physics_frame

func HitBoxEntered(area: Area2D) -> void :
    if over:
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if is_instance_valid(carryCharacter):
        return
    var character = area.get_parent()
    if character is TowerDefenseZombie:
        if character.isRise:
            return
        if character.camp != camp:
            return
        if !character.CanCollision(instance.maskFlags):
            return
        if character.instance.zombiePhysique > TowerDefenseEnum.ZOMBIE_PHYSIQUE.NORMAL:
            return
        if character.camp != camp:
            return
        if !character.targetRegistrationComponent.canCarry:
            return
        hitBox.disconnect("area_entered", HitBoxEntered)
        carryCharacter = character
        carryCharacter.set_deferred("isPause", true)
        carryCharacter.groundHeight = z + 60
        carryCharacter.z = z + 60
        if !isFly:
            if inWater:
                sprite.SetAnimation("RiseWater", false, 0.2)
            else:
                sprite.SetAnimation("Rise", false, 0.2)
            isFly = true
            await get_tree().create_timer(0.3, false).timeout
            isFlying = true

func FlyEntered() -> void :
    sprite.SetAnimation("Fly", true, 0.0)
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE

@warning_ignore("unused_parameter")
func FlyProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if !sprite.pause:
        if isFlying:
            global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
        if attackComponent.CanAttack():
            if is_instance_valid(attackComponent.target) && attackComponent.target is TowerDefenseZombie:
                attackComponent.Attack(config.smashAttack)

func FlyExited() -> void :
    pass

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if is_instance_valid(carryCharacter):
        carryCharacter.isGround = false
        carryCharacter.groundHeight = groundHeight
        carryCharacter.isPause = false
        carryCharacter = null

func Blow() -> void :
    if isFly:
        BlowBack(1.0, 1.0)

func Walk() -> void :
    if isFly:
        state.send_event("ToFly")
    else:
        state.send_event("ToWalk")

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Rise", "RiseWater":
            isFlying = true
            Walk()
