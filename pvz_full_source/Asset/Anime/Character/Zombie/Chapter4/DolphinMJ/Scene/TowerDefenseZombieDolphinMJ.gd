@tool
extends TowerDefenseZombie

@onready var spotlight2: Sprite2D = %Spotlight2
@onready var spotlight: Sprite2D = %Spotlight
@export var spotlightGrandient: Gradient

@onready var attackComponent2: AttackComponent = %AttackComponent2

var dolphin: bool = true:
    set(_dolphin):
        dolphin = _dolphin
        if !dolphin:
            useAttackDps = true
            attackComponent.attackType = "Eat"
            attackComponent.checkVase = false
            useAttackDps = true
            walkAnimeClip = "Walk"
            attackAnimeClip = "Eat"
            dieAnimeClip = "Death"
var jumpMove: bool = false
var isJump: bool = false
var isJumpInWater: bool = false
var isBlock: bool = false

var audioPlay: bool = false

var timer: float = 5.0

var dancerList: Array[TowerDefenseCharacter] = []
@export var dancerPacketName: String = "ZombieDolphinDC"

var firstSpawn: bool = false
var isSpawn: bool = false

func _ready() -> void :
    super._ready()
    dancerList.resize(4)
    sprite.animeStarted.connect(AnimeStarted)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if timer > 0.0:
        timer -= delta

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

    if !isSpawn:
        if timer <= 0.0:
            if CanSpawnDancer():
                if inWater:
                    sprite.SetAnimation("PointUp2", false, 0.0)
                    sprite.AddAnimation("PointDown2", 0.75, false, 0.0)
                elif dolphin:
                    sprite.SetAnimation("PointUp3", false, 0.0)
                    sprite.AddAnimation("PointDown3", 0.75, false, 0.0)
                else:
                    sprite.SetAnimation("PointUp4", false, 0.0)
                    sprite.AddAnimation("PointDown4", 0.75, false, 0.0)
                isSpawn = true

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    if !isSpawn:
        if timer <= 0.0:
            if CanSpawnDancer():
                if inWater:
                    sprite.SetAnimation("PointUp2", false, 0.0)
                    sprite.AddAnimation("PointDown2", 0.75, false, 0.0)
                elif dolphin:
                    sprite.SetAnimation("PointUp3", false, 0.0)
                    sprite.AddAnimation("PointDown3", 0.75, false, 0.0)
                else:
                    sprite.SetAnimation("PointUp4", false, 0.0)
                    sprite.AddAnimation("PointDown4", 0.75, false, 0.0)
                isSpawn = true

func Walk() -> void :
    if dolphin && inWater:
        state.send_event("ToRun")
    else:
        state.send_event("ToWalk")

func RunEntered() -> void :
    if inWater:
        if !inSwimPlay && inSwimAnimeClip != "":
            sprite.SetAnimation(inSwimAnimeClip, false, 0.2)
            sprite.AddAnimation("DolphinRun", 0.0, true, 0.0)
            inSwimPlay = true
        else:
            sprite.SetAnimation("DolphinRun", true, 0.0)
    else:
        sprite.SetAnimation(walkAnimeClip, true, 0.2)
    groundMoveComponent.alive = true

@warning_ignore("unused_parameter")
func RunProcessing(delta: float) -> void :
    if sprite.clip == inSwimAnimeClip:
        sprite.timeScale = timeScale * walkSpeedScale
    else:
        sprite.timeScale = timeScale * walkSpeedScale * 0.5
    if nearDie:
        return
    if TowerDefenseManager.backZombie:
        return
    if sprite.clip != inSwimAnimeClip && (sprite.clip == "DolphinRun" || sprite.clip == "PointUp1" || sprite.clip == "PointDown1"):
        if attackComponent2.CanAttack():
            if is_instance_valid(attackComponent2.target):
                state.send_event("ToJump")

    if !isSpawn:
        if timer <= 0.0:
            if CanSpawnDancer():
                groundMoveComponent.alive = false
                sprite.SetAnimation("PointUp1", false, 0.0)
                await get_tree().physics_frame
                await get_tree().physics_frame
                groundMoveComponent.alive = true
                sprite.AddAnimation("PointDown1", 0.0, false, 0.0)
                sprite.AddAnimation("DolphinRun", 0.0, true, 0.0)
                isSpawn = true


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
                    waterHeight = 48
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
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE

func InWater() -> void :
    super.InWater()
    if !dolphin:
        sprite.offset = Vector2(24, -97)


    useAttackDps = true

func OutWater() -> void :
    super.OutWater()
    var tween = create_tween()
    tween.tween_property(sprite, ^"offset", Vector2(-40, -92), 0.25)
    if dolphin:
        global_position.x -= scale.x * transformPoint.scale.x * 30.0
    useAttackDps = !dolphin
    waterHeight = 0

func DieEntered() -> void :
    super.DieEntered()
    sprite.offset = Vector2(-40, -92)
    if inWater:
        waterHeight = 60
        groundHeight = -60
        z = -60
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
        "spawn":
            if !die && !nearDie:
                SpawnDancer()
                spotlight.visible = true
                spotlight2.visible = true
                ChangeSpotlightColor()
                if !firstSpawn:
                    firstSpawn = true
                    AudioManager.AudioPlay("Dancer", AudioManagerEnum.TYPE.SFX)
                isSpawn = false

func AnimeStarted(clip: String) -> void :
    match clip:
        "DolphinRun":
            pass

            sprite.offset.x = 24

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "PointDown2", "PointDown3", "PointDown4":
            Walk()
        "DolphinJump":
            jumpMove = true
            waterHeight = 48
            groundHeight = - waterHeight
            z = groundHeight
            spriteGroup.position.y = - z
            sprite.offset.x = -40
            if !TowerDefenseManager.backZombie:
                global_position.x -= scale.x * transformPoint.scale.x * 98.0
            sprite.queue_redraw()
            Walk()
        "JumpInWater":
            if !TowerDefenseManager.backZombie:
                global_position.x -= scale.x * transformPoint.scale.x * 64.0
            sprite.offset.x = 24

func CanSpawnDancer() -> bool:
    var gridNum: Vector2 = TowerDefenseManager.GetMapGridNum()
    if gridPos.y > 1:
        if !is_instance_valid(dancerList[0]):
            return true
    if gridPos.y < gridNum.y:
        if !is_instance_valid(dancerList[1]):
            return true
    if !is_instance_valid(dancerList[2]):
        return true
    if !is_instance_valid(dancerList[3]):
        return true
    return false

func SpawnDancer() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(dancerPacketName)
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    if gridPos.y > 1:
        if !is_instance_valid(dancerList[0]) || (is_instance_valid(dancerList[0]) && (dancerList[0].nearDie || dancerList[0].nearDie)):
            var dancer = packetConfig.Create(Vector2(global_position.x, TowerDefenseManager.GetMapLineY(gridPos.y - 1)), gridPos - Vector2i(0, 1), 0)
            characterNode.add_child.call_deferred(dancer)
            ( func():
                if is_instance_valid(dancer):
                    if is_instance_valid(dancer.instance):
                        dancer.instance.hitpointScale = _hitpointScale
                    if is_instance_valid(dancer.transformPoint):
                        dancer.transformPoint.scale = _scale).call_deferred()
            if dancerPacketName == "ZombieDolphinDC":
                dancer.Rise.call_deferred(1.5, 0.0, true, false)
                dancer.dolphin = dolphin
                dancer.inSwimPlay = true
            else:
                dancer.Rise.call_deferred(1.5)
            dancer.invisible = invisible
            if instance.hypnoses:
                dancer.Hypnoses.call_deferred()
            dancerList[0] = dancer
    if gridPos.y < gridNum.y:
        if !is_instance_valid(dancerList[1]) || (is_instance_valid(dancerList[1]) && (dancerList[1].nearDie || dancerList[1].nearDie)):
            var dancer = packetConfig.Create(Vector2(global_position.x, TowerDefenseManager.GetMapLineY(gridPos.y + 1)), gridPos + Vector2i(0, 1), 0)
            characterNode.add_child.call_deferred(dancer)
            ( func():
                if is_instance_valid(dancer):
                    if is_instance_valid(dancer.instance):
                        dancer.instance.hitpointScale = _hitpointScale
                    if is_instance_valid(dancer.transformPoint):
                        dancer.transformPoint.scale = _scale).call_deferred()
            if dancerPacketName == "ZombieDolphinDC":
                dancer.Rise.call_deferred(1.5, 0.0, true, false)
                dancer.dolphin = dolphin
                dancer.inSwimPlay = true
            else:
                dancer.Rise.call_deferred(1.5)
            dancer.invisible = invisible
            if instance.hypnoses:
                dancer.Hypnoses.call_deferred()
            dancerList[1] = dancer
    if !is_instance_valid(dancerList[2]) || (is_instance_valid(dancerList[2]) && (dancerList[2].nearDie || dancerList[2].nearDie)):
        var dancer = packetConfig.Create(global_position - Vector2(gridSize.x * 1.25, 0), gridPos - Vector2i(1, 0), 0)
        characterNode.add_child.call_deferred(dancer)
        ( func():
            if is_instance_valid(dancer):
                if is_instance_valid(dancer.instance):
                    dancer.instance.hitpointScale = _hitpointScale
                if is_instance_valid(dancer.transformPoint):
                    dancer.transformPoint.scale = _scale).call_deferred()
        if dancerPacketName == "ZombieDolphinDC":
            dancer.Rise.call_deferred(1.5, 0.0, true, false)
            dancer.dolphin = dolphin
            dancer.inSwimPlay = true
        else:
            dancer.Rise.call_deferred(1.5)
        dancer.invisible = invisible
        if instance.hypnoses:
            dancer.Hypnoses.call_deferred()
        dancerList[2] = dancer
    if !is_instance_valid(dancerList[3]) || (is_instance_valid(dancerList[3]) && (dancerList[3].nearDie || dancerList[3].nearDie)):
        var dancer = packetConfig.Create(global_position + Vector2(gridSize.x * 1.25, 0), gridPos + Vector2i(1, 0), 0)
        characterNode.add_child.call_deferred(dancer)
        ( func():
            if is_instance_valid(dancer):
                if is_instance_valid(dancer.instance):
                    dancer.instance.hitpointScale = _hitpointScale
                if is_instance_valid(dancer.transformPoint):
                    dancer.transformPoint.scale = _scale).call_deferred()
        if dancerPacketName == "ZombieDolphinDC":
            dancer.Rise.call_deferred(1.5, 0.0, true, false)
            dancer.dolphin = dolphin
            dancer.inSwimPlay = true
        else:
            dancer.Rise.call_deferred(1.5)
        dancer.invisible = invisible
        if instance.hypnoses:
            dancer.Hypnoses.call_deferred()
        dancerList[3] = dancer

func ChangeSpotlightColor() -> void :
    var color = spotlightGrandient.sample(randf())
    spotlight.modulate = color
    spotlight2.modulate = color
    get_tree().create_timer(3.0, false).timeout.connect(ChangeSpotlightColor)

func RemoveDancer(dancer: TowerDefenseCharacter) -> void :
    var pos = dancerList.find(dancer)
    if pos != -1:
        dancerList[pos] = null

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    for dancer in dancerList:
        if is_instance_valid(dancer):
            dancer.jackson = null
    dancerList.clear()
    dancerList.resize(4)

func ExportVariantSave() -> Dictionary:
    return {
        "dolphin": dolphin, 
        "jumpMove": jumpMove, 
        "isJump": isJump, 
        "isBlock": isBlock, 
        "firstSpawn": firstSpawn, 
        "isSpawn": isSpawn, 
        "timer": timer, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    dolphin = data.get("dolphin", true)
    jumpMove = data.get("jumpMove", false)
    isJump = data.get("isJump", false)
    isBlock = data.get("isBlock", false)
    firstSpawn = data.get("firstSpawn", false)
    isSpawn = data.get("isSpawn", false)
    timer = data.get("timer", 5.0)

func CanBlock() -> bool:
    return dolphin

func BlockType() -> String:
    return "Jump"

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    dolphin = false
    waterHeight = 48
    groundHeight = - waterHeight
    z = groundHeight
    spriteGroup.position.y = - z
    sprite.offset.x = -40
    isBlock = true
    AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
    Walk()
