class_name EffectCreateComponent extends ComponentBase

const MAX_EFFECT_COUNT: = 100

var parent: TowerDefenseCharacter

func GetName() -> String:
    return "EffectCreateComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func CreateDirt() -> TowerDefenseEffectParticlesOnce:
    if TowerDefenseManager.GetEffectCount() > MAX_EFFECT_COUNT:
        return
    var effect: TowerDefenseEffectParticlesOnce = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.PARTICLES_RISE_DIRT, TowerDefenseGroundItemBase.characterNode)
    effect.gridPos = parent.gridPos
    effect.global_position = Vector2(parent.shadowSprite.global_position.x, parent.shadowComponent.GetShadowPosition().y)
    return effect

func CreateSplash() -> TowerDefenseEffectSpriteOnce:
    if TowerDefenseManager.GetEffectCount() > MAX_EFFECT_COUNT:
        return
    var effect: TowerDefenseEffectSpriteOnce = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.PARTICLES_SPLASH, TowerDefenseGroundItemBase.characterNode)
    effect.gridPos = parent.gridPos
    effect.global_position = Vector2(parent.shadowSprite.global_position.x, parent.shadowComponent.GetShadowPosition().y)
    return effect

func CreateIceTrap() -> TowerDefenseEffectParticlesOnce:
    var effect: TowerDefenseEffectParticlesOnce = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.PARTICLES_ICE_TRAP, TowerDefenseGroundItemBase.characterNode)
    effect.gridPos = parent.gridPos
    effect.global_position = Vector2(parent.shadowSprite.global_position.x, parent.shadowComponent.GetShadowPosition().y)
    return effect
