
class_name ScaredComponent extends ComponentBase


signal scaredDown()

signal scaredRise()


@onready var state: StateChart = %StateChart


var parent: TowerDefenseCharacter


@export var attackComponent: AttackComponent

@export var controlComponentList: Array[ComponentBase]
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var scaredDownAnimeClip: String = "Scared"

@export var scaredDownAnimeTimeScale: float = 1.0

@export var scaredIdleAnimeClip: String = "ScaredIdle"

@export var scaredIdleAnimeTimeScale: float = 1.0

@export var scaredGrowAnimeClip: String = "Grow"

@export var scaredGrowAnimeTimeScale: float = 1.0


var height: TowerDefenseEnum.CHARACTER_HEIGHT = TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL


func GetName() -> String:
    return "ScaredComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return

    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return




func IdleEntered() -> void :
    if !alive:
        return
    parent.Idle()


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return

    if attackComponent.CanAttack():
        parent.Component()
        state.send_event("ToScaredDown")
        return


func IdleExited() -> void :
    pass


func ScaredDownEntered() -> void :
    scaredDown.emit()
    SetScared(true)
    sprite.SetAnimation(scaredDownAnimeClip, false, 0.2)


@warning_ignore("unused_parameter")
func ScaredDownProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * scaredDownAnimeTimeScale


func ScaredDownExited() -> void :
    pass


func ScaredIdleEntered() -> void :
    sprite.SetAnimation(scaredIdleAnimeClip, true)


@warning_ignore("unused_parameter")
func ScaredIdleProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * scaredIdleAnimeTimeScale
    if !attackComponent.CanAttack():
        state.send_event("ToScaredGrow")


func ScaredIdleExited() -> void :
    pass


func ScaredGrowEntered() -> void :
    sprite.SetAnimation(scaredGrowAnimeClip, false, 0.2)


@warning_ignore("unused_parameter")
func ScaredGrowProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * scaredGrowAnimeTimeScale


func ScaredGrowExited() -> void :
    pass


func AnimeCompleted(clip: String) -> void :
    if !alive:
        return
    match clip:
        scaredDownAnimeClip:
            state.send_event("ToScaredIdle")
        scaredGrowAnimeClip:
            scaredRise.emit()
            SetScared(false)
            state.send_event("ToIdle")



func SetScared(scared: bool) -> void :
    if scared:
        height = parent.instance.height
        parent.instance.height = TowerDefenseEnum.CHARACTER_HEIGHT.LOW
        for component: ComponentBase in controlComponentList:
            component.alive = false
    else:
        parent.instance.height = height
        for component: ComponentBase in controlComponentList:
            component.alive = true
