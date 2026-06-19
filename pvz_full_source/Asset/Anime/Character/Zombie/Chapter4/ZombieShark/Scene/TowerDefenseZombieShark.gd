@tool
extends TowerDefenseZombie

@onready var chomperComponent: ChomperComponent = %ChomperComponent

var audioPlay: bool = false
var originalWaterHeight: float = 0.0

func _ready() -> void :
    originalWaterHeight = waterHeight
    super._ready()
    if Engine.is_editor_hint():
        return
    sprite.animeStarted.connect(AnimeStarted)

func BlowBack(num: float, time: float = 1.0) -> void :
    if inWater:
        return
    super.BlowBack(num, time)

func AttackEntered() -> void :
    super.AttackEntered()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

func AttackExited() -> void :
    super.AttackExited()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

func WalkProcessing(delta: float) -> void :
    super.WalkProcessing(delta)
    if !audioPlay:
        if global_position.x < TowerDefenseManager.GetMapGroundRight():
            AudioManager.AudioPlay("DolphinAppears", AudioManagerEnum.TYPE.SFX)
            audioPlay = true

func Walk() -> void :
    if inWater:
        state.send_event("ToRun")
    else:
        state.send_event("ToWalk")

func RunEntered() -> void :
    if inWater:
        if !inSwimPlay && inSwimAnimeClip != "":
            sprite.SetAnimation(inSwimAnimeClip, false, 0.2)
            sprite.AddAnimation("SwimRun", 0.0, true, 0.2)
            inSwimPlay = true
        else:
            sprite.SetAnimation("SwimRun", true, 0.2)
    else:
        sprite.SetAnimation(walkAnimeClip, true, 0.2)
    groundMoveComponent.alive = true

@warning_ignore("unused_parameter")
func RunProcessing(delta: float) -> void :
    if sprite.clip == inSwimAnimeClip:
        sprite.timeScale = timeScale * walkSpeedScale * 2.0
    else:
        sprite.timeScale = timeScale * walkSpeedScale * 0.5
    if nearDie:
        return
    if sprite.clip == "SwimRun":
        chomperComponent.alive = true

func RunExited() -> void :
    groundMoveComponent.alive = false

func InWater() -> void :
    waterHeight = originalWaterHeight
    super.InWater()
    useAttackDps = false
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

func OutWater() -> void :
    super.OutWater()
    var tween = create_tween()
    tween.tween_property(sprite, ^"offset", Vector2(-40, -92), 0.25)
    useAttackDps = true
    chomperComponent.alive = false
    waterHeight = 0
    global_position.x -= scale.x * transformPoint.scale.x * 10.0
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

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























func AnimeStarted(clip: String) -> void :
    match clip:
        "DolphinRun":
            pass

            sprite.offset.x = 24

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "ChewOver":
            Walk()
        "JumpInWater":
            global_position.x -= scale.x * transformPoint.scale.x * 64.0
            sprite.offset.x = 24


func ChewOver() -> void :
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER


func ChewBegin() -> void :
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
