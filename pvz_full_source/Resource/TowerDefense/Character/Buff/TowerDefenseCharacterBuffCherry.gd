class_name TowerDefenseCharacterBuffCherry extends TowerDefenseCharacterBuffConfig

const CHERRY_BOMB_EXPLOSION = preload("uid://cibtjjjomdxnh")

const CHERRY_COLOR: Color = Color(1.0, 0.628, 0.571, 1.0)

@export var time: float = 3.0

@export_storage var currentTime: float = 0.0

func _init() -> void :
    key = "Cherry"

func Enter() -> void :
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.CHERRY:
        character.buff.BuffDelete("Cherry")
        return

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    character.sprite.meshColor *= CHERRY_COLOR
    currentTime += delta
    return currentTime >= time

func Exit() -> void :
    pass

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time + randf_range(-0.2, 0.2))
    currentTime = 0.0

func Destroy() -> void :
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var effect = TowerDefenseManager.CreateEffectParticlesOnce(CHERRY_BOMB_EXPLOSION, character.gridPos)
    characterNode.add_child(effect)
    effect.global_position = character.global_position

    var hurtEvent = TowerDefenseCharacterEventExplodeHurt.new()
    hurtEvent.num = 100
    var camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL
    if character.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
    if character.camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
        camp = TowerDefenseEnum.CHARACTER_CAMP.PLANT
    AudioManager.AudioPlay("ExplodeCherrybomb", AudioManagerEnum.TYPE.SFX)
    TowerDefenseExplode.CreateExplode(character.global_position, Vector2(1.4, 1.4), [hurtEvent], [], camp, -1)
