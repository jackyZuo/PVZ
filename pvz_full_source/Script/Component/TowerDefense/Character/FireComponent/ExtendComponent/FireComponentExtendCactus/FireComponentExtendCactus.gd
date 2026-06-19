
class_name FireComponentExtendCactus extends FireComponentExtendBase


@onready var state: StateChart = %StateChart

@export var fireComponent: FireComponent

@export var sprite: AdobeAnimateSprite

@export var upAnimeClips: String = "Up"

@export var upAnimeTimeScale: float = 2.0

@export var downAnimeClips: String = "Down"

@export var downAnimeTimeScale: float = 2.0

@export var upFireAnimeClips: String = "UpFire"

@export var downFireAnimeClips: String = "Fire"


signal upOver()

signal downOver()


var up: bool = false


var canRun: bool = false


func GetName() -> String:
    return "FireComponentExtendCactus"


func _ready() -> void :
    super._ready()
    if is_instance_valid(sprite):
        sprite.animeCompleted.connect(AnimeCompleted)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if !alive:
        return


func IsUp() -> bool:
    return up


func IdleEntered() -> void :
    if !up:
        fireComponent.fireAnimeClips = downFireAnimeClips
    else:
        fireComponent.fireAnimeClips = upFireAnimeClips


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if fireComponent.CanFire(null, TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
        canRun = false
        if !up:
            parent.Component()
            state.send_event("ToUp")
        else:
            canRun = true
        return
    else:
        canRun = false
        if fireComponent.timer <= 0 && fireComponent.checkIntreval == 0:
            if up:
                parent.Component()
                state.send_event("ToDown")
                return

    if fireComponent.CanFire(null, TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM):
        canRun = false
        if up:
            parent.Component()
            state.send_event("ToDown")
        else:
            canRun = true
        return


func IdleExited() -> void :
    pass


func UpEntered() -> void :
    sprite.SetAnimation(upAnimeClips, true, 0.2)
    up = true


@warning_ignore("unused_parameter")
func UpProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * upAnimeTimeScale


func UpExited() -> void :
    pass


func DownEntered() -> void :
    sprite.SetAnimation(downAnimeClips, true, 0.2)
    up = false


@warning_ignore("unused_parameter")
func DownProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * downAnimeTimeScale


func DownExited() -> void :
    pass


func AnimeCompleted(clip: String) -> void :
    match clip:
        upAnimeClips:
            upOver.emit()
            state.send_event("ToIdle")
            parent.Idle()
        downAnimeClips:
            downOver.emit()
            state.send_event("ToIdle")
            parent.Idle()


func CanRun() -> bool:
    if is_instance_valid(preExtend):
        return preExtend.CanRun()
    return canRun
