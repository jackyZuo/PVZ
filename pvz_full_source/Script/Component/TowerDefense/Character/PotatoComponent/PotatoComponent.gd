
class_name PotatoComponent extends ComponentBase


const MINE_RISE_DIRT = preload("uid://cov352ltsv2sg")


@onready var state: StateChart = %StateChart

@onready var timerComponent: TimerComponent = %TimerComponent


@export var attackComponent: AttackComponent

@export var explodeComponent: ExplodeComponent

@export var readyTime: float = 15.0
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var readyAnimeClips: String = "Ready"

@export var readyAnimeTimeScale: float = 1.0

@export var riseAnimeClips: String = "Rise"

@export var riseAnimeTimeScale: float = 1.0

@export var chargeAnimeClips: String = "Idle"

@export var chargeAnimeTimeScale: float = 1.0


var parent: TowerDefenseCharacter


var rise: bool = false

var isCharge: bool = false


var over: bool = false


func GetName() -> String:
    return "PotatoComponent"


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
    if parent.componentRunning:
        parent.Idle()


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if TowerDefenseManager.IsIZMMode():
        if parent is not TowerDefenseZombie:
            parent.Component()
            state.send_event("ToCharge")
        else:
            state.send_event("ToReady")
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    if rise:
        state.send_event("ToRise")
        return
    if parent is not TowerDefenseZombie:
        parent.Component()
    state.send_event("ToReady")


func IdleExited() -> void :
    pass


func ReadyEntered() -> void :
    if is_instance_valid(sprite):
        sprite.SetAnimation(readyAnimeClips, true)
    timerComponent.Run("Ready", readyTime)


@warning_ignore("unused_parameter")
func ReadyProcessing(delta: float) -> void :
    if is_instance_valid(sprite) && is_instance_valid(parent):
        sprite.timeScale = parent.timeScale * readyAnimeTimeScale
    timerComponent.timeScale = parent.timeScale


func ReadyExited() -> void :
    pass


func RiseEntered() -> void :
    AudioManager.AudioPlay("GravestoneRumble", AudioManagerEnum.TYPE.SFX)
    if is_instance_valid(sprite):
        sprite.SetAnimation(riseAnimeClips, false)


@warning_ignore("unused_parameter")
func RiseProcessing(delta: float) -> void :
    if is_instance_valid(sprite) && is_instance_valid(parent):
        sprite.timeScale = parent.timeScale * riseAnimeTimeScale


func RiseExited() -> void :
    pass


func ChargeEntered() -> void :
    isCharge = true
    parent.instance.invincibleSmash = true
    if is_instance_valid(sprite):
        sprite.SetAnimation(chargeAnimeClips, true)


@warning_ignore("unused_parameter")
func ChargeProcessing(delta: float) -> void :
    if is_instance_valid(sprite) && is_instance_valid(parent):
        sprite.timeScale = parent.timeScale * chargeAnimeTimeScale
    if over:
        return
    if is_instance_valid(attackComponent):
        if attackComponent.CanAttack():
            over = true
            Explode()
            parent.Destroy()


func ChargeExited() -> void :
    pass


func ReadyRise() -> void :
    if rise:
        return
    rise = true
    state.send_event("ToRise")
    timerComponent.Stop("Ready")
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(MINE_RISE_DIRT, parent.gridPos)
    effect.global_position = parent.global_position
    parent.characterNode.add_child(effect)


func AnimeCompleted(clip: String) -> void :
    match clip:
        riseAnimeClips:
            state.send_event("ToCharge")


func Explode() -> void :
    if is_instance_valid(explodeComponent):
        explodeComponent.Explode()


func Timeout(timerName: String) -> void :
    match timerName:
        "Ready":
            ReadyRise()

func ExportComponentSave() -> Dictionary:
    return {
        "rise": rise, 
        "isCharge": isCharge, 
        "over": over, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    rise = _data.get("rise", false)
    isCharge = _data.get("isCharge", false)
    over = _data.get("over", false)

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "rise": rise, 
        "isCharge": isCharge, 
        "over": over, 
    }
    if is_instance_valid(state) and is_instance_valid(state._state) and state._state is CompoundState and is_instance_valid(state._state._active_state):
        data["state"] = state._state._active_state.name
    return data

func SyncDeserialize(data: Dictionary) -> void :
    rise = data.get("rise", false)
    isCharge = data.get("isCharge", false)
    over = data.get("over", false)
    if data.has("state"):
        _sync_force_state(data["state"])

func _sync_force_state(target_state: String) -> void :
    if !is_instance_valid(state) or !is_instance_valid(state._state):
        return
    if !(state._state is CompoundState) or !is_instance_valid(state._state._active_state):
        return
    if state._state._active_state.name == target_state:
        return
    state.send_event("To" + target_state)
