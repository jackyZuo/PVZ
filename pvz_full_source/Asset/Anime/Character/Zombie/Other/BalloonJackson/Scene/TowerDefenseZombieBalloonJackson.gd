@tool
extends TowerDefenseZombie

var pop: bool = false

var speed: float = 30.0

var audioPlay: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater"], true)

func FlyEntered() -> void :
    sprite.SetAnimation("Idle", true, 0.2)

@warning_ignore("unused_parameter")
func FlyProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if !sprite.pause:
        global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)

    if global_position.x < TowerDefenseManager.GetMapGroundLeft() + 20:
        instance.ArmorDelete("Balloon")
        return
    if !audioPlay:
        if global_position.x < TowerDefenseManager.GetMapGroundRight():
            AudioManager.AudioPlay("BalloonInflate", AudioManagerEnum.TYPE.SFX)
            audioPlay = true
    if !sprite.pause && attackComponent.CanAttack():
        state.send_event("ToFlyAttack")

func FlyExited() -> void :
    pass

func PopEntered() -> void :
    sprite.SetAnimation("Pop", false, 0.2)

@warning_ignore("unused_parameter")
func PopProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func PopExited() -> void :
    pass

func FlyAttackEntered():
    sprite.SetAnimation("FlyEat", true, 0.2)
    startAttack = false
    await get_tree().create_timer(0.1, false).timeout
    startAttack = true

@warning_ignore("unused_parameter")
func FlyAttackProcessing(delta: float) -> void :
    if !attackComponent.CanAttack():
        state.send_event("ToFly")
    else:
        if startAttack && !nearDie && !sprite.pause && sprite.timeScale > 0 && useAttackDps:
            attackComponent.AttackDps(delta, config.attack)
    sprite.timeScale = timeScale * 2.0

func FlyAttackExited() -> void :
    pass

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func Walk() -> void :
    if pop:
        state.send_event("ToWalk")
    else:
        state.send_event("ToFly")

func Blow() -> void :
    if !pop:
        HitBoxDestroy()
        var tween = create_tween()
        tween.tween_property(self, ^"global_position:x", global_position.x + TowerDefenseManager.GetMapGridSize().y * TowerDefenseManager.GetMapGridNum().y * 2.0, 1.0)
        await tween.finished
        Destroy()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Pop":
            Walk()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Balloon":
            AudioManager.AudioPlay("BalloonPop", AudioManagerEnum.TYPE.SFX)
            instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
            instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
            if !GetHasArmor("SpecialHelmet"):
                instance.unUseBuffFlags = 0
            else:
                instance.armorOverrideUnUseBuffFlagSave = 0
            if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                pop = true
                state.send_event("ToPop")
                return
            var spawn_pos: Vector2 = global_position + Vector2(4.0, 0.0)
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieJacksonBlackHelmet")
            var zombie = packetConfig.Create(spawn_pos, gridPos, 40)
            characterNode.add_child(zombie)
            if is_instance_valid(zombie):
                if is_instance_valid(zombie.instance):
                    zombie.instance.hitpointScale = instance.hitpointScale
                if is_instance_valid(zombie.transformPoint):
                    zombie.transformPoint.scale = transformPoint.scale
            zombie.invisible = invisible
            if instance.hypnoses:
                zombie.Hypnoses()
            if is_instance_valid(zombie):
                zombie.Walk.call_deferred()
                pop = true
                state.send_event("ToPop")
            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                var control = TowerDefenseManager.currentControl
                if is_instance_valid(control):
                    var _sync_id: int = control._get_next_sync_id()
                    control._register_sync_character(_sync_id, zombie)
                    MultiPlayerManager.SendSpawnCharacterAt("ZombieJacksonBlackHelmet", gridPos.x, gridPos.y, _sync_id, instance.hitpointScale, transformPoint.scale.x, instance.hypnoses, 0.0, true, spawn_pos.x, spawn_pos.y, true, 40.0)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            sprite.head = false
            DamagePartCreate("Head", sprite.propeller)
