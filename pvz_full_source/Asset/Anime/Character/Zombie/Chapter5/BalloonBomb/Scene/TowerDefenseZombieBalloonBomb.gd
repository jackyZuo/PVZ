@tool
extends TowerDefenseZombie

const JACKBOX_EXPLOSION = preload("uid://cxnt2jbnk48fp")

@export var eventList: Array[TowerDefenseCharacterEventBase]

var speed: float = 100.0

var audioPlay: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    targetRegistrationComponent.canCarry = false
    AudioManager.AudioPlay("BalloonInflate", AudioManagerEnum.TYPE.SFX)

func FlyEntered() -> void :
    sprite.SetAnimation("Idle", true, 0.2)

@warning_ignore("unused_parameter")
func FlyProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if !sprite.pause:
        global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
    if global_position.x < TowerDefenseManager.GetMapGroundLeft() + 20:
        state.send_event("ToFlyAttack")
        return
    if !sprite.pause && attackComponent.CanAttack():
        state.send_event("ToFlyAttack")

func FlyExited() -> void :
    pass

func FlyAttackEntered():
    HitBoxDestroy()
    sprite.SetAnimation("Attack", false, 0.2)

@warning_ignore("unused_parameter")
func FlyAttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func FlyAttackExited() -> void :
    pass

func Walk() -> void :
    state.send_event("ToFly")

func Blow() -> void :
    HitBoxDestroy()
    var tween = create_tween()
    tween.tween_property(self, ^"global_position:x", global_position.x + TowerDefenseManager.GetMapGridSize().y * TowerDefenseManager.GetMapGridNum().y * 2.0, 1.0)
    await tween.finished
    Destroy()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "attack":
            CreateEffect()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Attack":
            Destroy()

func CreateEffect() -> void :
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(JACKBOX_EXPLOSION, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.25, 1.25), eventList, [], camp, -1)
    AudioManager.AudioPlay("ExplodeCherrybomb", AudioManagerEnum.TYPE.SFX)
