extends TowerDefenseProjectileEffectBase

const CHERRY_BOMB_EXPLOSION = preload("uid://cibtjjjomdxnh")

func _ready() -> void :
    EffectCreate()
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.3, 1.3), eventList, [], camp, -1)
    await get_tree().physics_frame
    queue_free()

func EffectCreate() -> void :
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 3.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(CHERRY_BOMB_EXPLOSION, gridPos)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    effect.global_position = global_position
    if is_instance_valid(cell):
        effect.global_position.y -= (cell.GetGroundHeight() - 30)
    characterNode.add_child(effect)
    AudioManager.AudioPlay("ExplodeCherrybomb", AudioManagerEnum.TYPE.SFX)
