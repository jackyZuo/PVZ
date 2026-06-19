@tool
extends TowerDefenseZombie
const JACK_IN_THE_BOX = preload("uid://dhnsy8kekj0nm")
const JACKBOX_EXPLOSION = preload("uid://cxnt2jbnk48fp")

static var jackInTheBox: AudioStreamPlayerMember

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var hasJackBox: bool = true

var over: bool = false

var timer: float = 0.0
var time: float = 0.0
var explode: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    add_to_group("JackBox")
    time = randf_range(9.0, 20.0)
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !is_instance_valid(jackInTheBox):
        jackInTheBox = AudioManager.MemberFind("JackInTheBox", AudioManagerEnum.TYPE.SFX)
        jackInTheBox.max_polyphony = 1
        jackInTheBox.process_mode = Node.PROCESS_MODE_PAUSABLE

    jackInTheBox.play()

    await get_tree().create_timer(0.1).timeout
    if TowerDefenseManager.GetGameMethod() == TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
        explode = true
        instance.unUseBuffFlags += TowerDefenseEnum.CHARACTER_BUFF_FLAGS.GARLIC
        if !hasJackBox || nearDie || die:
            return
        state.send_event("ToBomb")
        return

func TreeExiting() -> void :
    remove_from_group("JackBox")
    if is_instance_valid(jackInTheBox):
        if get_tree().get_node_count_in_group("JackBox") <= 0:
            jackInTheBox.stop()

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !explode:
        if !sprite.pause:
            if timer < time:
                timer += delta * timeScale
            else:
                explode = true
                instance.unUseBuffFlags += TowerDefenseEnum.CHARACTER_BUFF_FLAGS.GARLIC
                if !hasJackBox || nearDie || die:
                    return
                state.send_event("ToBomb")


func BombEntered() -> void :
    AudioManager.AudioPlay("JackSurprise", AudioManagerEnum.TYPE.SFX)
    sprite.SetAnimation("Bomb", false, 0.2)

@warning_ignore("unused_parameter")
func BombProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func BombExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Bomb":
            if over:
                return
            over = true
            if hasJackBox:
                CreateEffect()
                Destroy()
            else:
                super.Walk()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Jackbox":
            hasJackBox = false

func Walk() -> void :
    if explode:
        return
    super.Walk()

func CreateEffect() -> void :
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(JACKBOX_EXPLOSION, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.25, 1.25), eventList, [], camp, -1)
    AudioManager.AudioPlay("ExplodeCherrybomb", AudioManagerEnum.TYPE.SFX)
