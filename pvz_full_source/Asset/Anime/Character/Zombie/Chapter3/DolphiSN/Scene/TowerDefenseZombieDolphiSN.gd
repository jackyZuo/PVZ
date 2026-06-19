@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2

var dolphin: bool = true:
    set(_dolphin):
        dolphin = _dolphin
        if !dolphin:
            useAttackDps = true
            attackComponent.attackType = "Eat"
            useAttackDps = true
            walkAnimeClip = "Walk"
            attackAnimeClip = "Eat"
            dieAnimeClip = "Death"
var jumpMove: bool = false
var isJump: bool = false
var isJumpInWater: bool = false
var isBlock: bool = false

var audioPlay: bool = false

func _ready() -> void :
    super._ready()
    sprite.animeStarted.connect(AnimeStarted)

func AttackEntered() -> void :
    super.AttackEntered()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

func AttackExited() -> void :
    super.AttackEntered()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

func WalkEntered() -> void :
    if jumpMove:
        jumpMove = false
        if inWater:
            sprite.SetAnimation(swimAnimeClip, true, 0.0)
        else:
            sprite.SetAnimation(walkAnimeClip, true, 0.0)
    else:
        if isBlock:
            isBlock = false
            if inWater:
                sprite.SetAnimation(swimAnimeClip, true, 0.0)
            else:
                sprite.SetAnimation(walkAnimeClip, true, 0.0)
        else:
            if inWater:
                sprite.SetAnimation(swimAnimeClip, true, 0.2)
            else:
                sprite.SetAnimation(walkAnimeClip, true, 0.2)
    await get_tree().create_timer(0.1, false).timeout
    groundMoveComponent.alive = true

func WalkProcessing(delta: float) -> void :
    super.WalkProcessing(delta)
    if !audioPlay:
        if global_position.x < TowerDefenseManager.GetMapGroundRight():
            AudioManager.AudioPlay("DolphinAppears", AudioManagerEnum.TYPE.SFX)
            audioPlay = true

func Walk() -> void :
    if dolphin && inWater:
        state.send_event("ToRun")
    else:
        state.send_event("ToWalk")

func RunEntered() -> void :
    if inWater:
        if !inSwimPlay && inSwimAnimeClip != "":
            sprite.SetAnimation(inSwimAnimeClip, false, 0.2)
            sprite.AddAnimation("DolphinRun", 0.0, true, 0.2)
            inSwimPlay = true
        else:
            sprite.SetAnimation("DolphinRun", true, 0.2)
    else:
        sprite.SetAnimation(walkAnimeClip, true, 0.2)
    groundMoveComponent.alive = true

@warning_ignore("unused_parameter")
func RunProcessing(delta: float) -> void :
    if sprite.clip == inSwimAnimeClip:
        sprite.timeScale = timeScale * walkSpeedScale * 1.0
    else:
        sprite.timeScale = timeScale * walkSpeedScale * 0.5
    if nearDie:
        return
    if TowerDefenseManager.backZombie:
        return
    if sprite.clip == "DolphinRun":
        if attackComponent2.CanAttack():
            if is_instance_valid(attackComponent2.target):
                state.send_event("ToJump")

func RunExited() -> void :
    groundMoveComponent.alive = false

func JumpEntered() -> void :
    shadowSprite.visible = false
    sprite.SetAnimation("DolphinJump", false, 0.2)
    instance.collisionFlags = 0
    instance.maskFlags = 0

@warning_ignore("unused_parameter")
func JumpProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if !TowerDefenseManager.backZombie:
        global_position.x -= scale.x * delta * sprite.timeScale * 16.0
    if isJump:
        if attackComponent2.CanAttack():
            if is_instance_valid(attackComponent2.target):
                if attackComponent2.target.instance.height >= TowerDefenseEnum.CHARACTER_HEIGHT.TALL:
                    dolphin = false
                    global_position.x = attackComponent2.target.global_position.x + 40
                    waterHeight = 40
                    groundHeight = - waterHeight
                    z = groundHeight
                    spriteGroup.position.y = - z
                    sprite.offset.x = -40
                    isBlock = true
                    AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
                    Walk()

func JumpExited() -> void :
    isJump = false
    if !inWater:
        shadowSprite.visible = !invisible
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

func InWater() -> void :
    super.InWater()
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER
    if !dolphin:
        sprite.offset = Vector2(24, -97)


    useAttackDps = true

func OutWater() -> void :
    super.OutWater()
    waterHeight = 0
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
    var tween = create_tween()
    tween.tween_property(sprite, ^"offset", Vector2(-40, -92), 0.25)
    if dolphin:
        global_position.x -= scale.x * transformPoint.scale.x * 30.0
    useAttackDps = !dolphin

func DieEntered() -> void :
    super.DieEntered()
    sprite.offset = Vector2(-40, -92)
    if inWater:
        waterHeight = 50
        groundHeight = - waterHeight
        z = groundHeight
        var tween = create_tween()
        tween.set_parallel(true)
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(self, "groundHeight", -100.0, 1.0)

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "hit":
            if !die && !nearDie && !sprite.pause:
                attackComponent.Attack(config.smashAttack)
        "audio":
            AudioManager.AudioPlay("DolphinBeforeJumping", AudioManagerEnum.TYPE.SFX)
        "check":
            isJump = true
        "jumpOver":
            dolphin = false

func AnimeStarted(clip: String) -> void :
    match clip:
        "DolphinRun":
            pass

            sprite.offset.x = 24

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "DolphinJump":
            jumpMove = true
            waterHeight = 48
            groundHeight = - waterHeight
            z = groundHeight
            spriteGroup.position.y = - z
            sprite.offset.x = -40
            if !TowerDefenseManager.backZombie:
                global_position.x -= scale.x * transformPoint.scale.x * 104.0
            sprite.queue_redraw()
            Walk()
        "JumpInWater":
            if !TowerDefenseManager.backZombie:
                global_position.x -= scale.x * transformPoint.scale.x * 64.0
            sprite.offset.x = 24

func CanBlock() -> bool:
    return dolphin

func BlockType() -> String:
    return "Jump"

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    dolphin = false
    waterHeight = 40
    groundHeight = - waterHeight
    z = groundHeight
    spriteGroup.position.y = - z
    sprite.offset.x = -40
    isBlock = true
    AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
    Walk()
