extends TowerDefenseProjectileEffectBase

const GLOOM_SQUID_SPLATS_SCENE: PackedScene = preload("uid://vc2i84jbs3fd")

var num: int = 4

func _ready() -> void :
    AttackCreate()

func AttackCreate() -> void :
    num -= 1
    AudioManager.AudioPlay("SplatNormal", AudioManagerEnum.TYPE.SFX)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var effect: TowerDefenseEffectParticlesOnce = GLOOM_SQUID_SPLATS_SCENE.instantiate()
    effect.objectId = ObjectManagerConfig.OBJECT.NOONE
    characterNode.add_child(effect)
    effect.Refresh()
    effect.gridPos = gridPos
    if !is_instance_valid(target):
        effect.global_position = global_position - Vector2(0, height)
        TowerDefenseExplode.CreateExplode(global_position - Vector2(0, height), Vector2(1.25, 1.25), eventList, [], camp, collisionFlag)
    else:
        effect.global_position = target.transformPoint.global_position - Vector2(0, 50)
        TowerDefenseExplode.CreateExplode(target.transformPoint.global_position - Vector2(0, 50), Vector2(1.25, 1.25), eventList, [], camp, collisionFlag)
    if num <= 0:
        queue_free()
