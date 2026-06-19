@tool
extends TowerDefenseItem

const CHERRY_BOMB_EXPLOSION = preload("uid://cibtjjjomdxnh")

@onready var magnetComponent: MagnetComponent = %MagnetComponent

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var armor: TowerDefenseArmorInstance

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    HitBoxDestroy()

    await get_tree().physics_frame

    if await magnetComponent.CanArmorDraw():
        armor = await magnetComponent.ArmorDrawNear()

    await get_tree().create_timer(1.0, false).timeout
    Destroy()

@warning_ignore("unused_parameter")
func Destroy(freeInsance: bool = true) -> void :
    magnetComponent.Destroy()
    super.Destroy(freeInsance)

func DestroySet() -> void :
    if over:
        return
    over = true
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(CHERRY_BOMB_EXPLOSION, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30)
    characterNode.add_child(effect)
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.5, 1.5), eventList, [], camp, -1)
    AudioManager.AudioPlay("ExplodeCherrybomb", AudioManagerEnum.TYPE.SFX)
    await get_tree().physics_frame
