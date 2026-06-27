@tool
extends TowerDefensePlant

const SQUASH_CANDY_THROW_PARTICLES = preload("uid://c4qigqg84djb")

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var squashComponent: SquashComponent = %SquashComponent

@export var eventList: Array[TowerDefenseCharacterEventBase]

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.invincible = true
    await get_tree().create_timer(0.5, false).timeout
    if !squashComponent.IsRunning():
        instance.invincible = false

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale

func JumpDownSmash() -> void :
    CreateParticlesEffect()
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.4, 1.4), eventList, [], camp, instance.collisionFlags | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND)

func CreateParticlesEffect() -> TowerDefenseEffectParticlesOnce:
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(SQUASH_CANDY_THROW_PARTICLES, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30)
    characterNode.add_child(effect)
    return effect
