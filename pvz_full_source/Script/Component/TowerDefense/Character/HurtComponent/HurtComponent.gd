class_name HurtComponent extends ComponentBase

const HEALTH = preload("uid://b8c40r4tk45sf")
const MAX_EFFECT_COUNT: = 100

var parent: TowerDefenseCharacter
var _pipeline: DamagePipeline

func GetName() -> String:
    return "HurtComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready
    _pipeline = TowerDefenseManager.damagePipeline

func HurtWithAttackConfig(attackConfig: AttackConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    parent.Bright()
    return _pipeline.ApplyHurtWithAttackConfig(parent, attackConfig, playSplatAudio, velocity, createDamagePart)

func Hurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    parent.Bright()
    return _pipeline.ApplyHurt(parent, num, playSplatAudio, velocity, true, createDamagePart)

func SkipInvincibleHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    parent.Bright()
    return _pipeline.ApplySkipInvincibleHurt(parent, num, playSplatAudio, velocity, true, createDamagePart)

func Health(num: float) -> void :
    parent.Bright()
    if is_instance_valid(parent.resourceSpawnComponent):
        parent.resourceSpawnComponent.HealthEffect(num)
        return
    parent.instance.Health(num)
    if TowerDefenseManager.GetEffectCount() > MAX_EFFECT_COUNT:
        return
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(HEALTH, parent.gridPos, "Idle")
    TowerDefenseGroundItemBase.characterNode.add_child(effect)
    effect.gridPos = parent.gridPos
    effect.global_position = Vector2(parent.shadowSprite.global_position.x, parent.shadowComponent.GetShadowPosition().y)

func BowlingHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, hitShield: bool = true, createDamagePart: bool = true) -> float:
    parent.Bright()
    return _pipeline.ApplySkipInvincibleHurt(parent, num, playSplatAudio, velocity, hitShield, createDamagePart)

func SmashHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    parent.Bright()
    return _pipeline.ApplySmashHurt(parent, num, playSplatAudio, velocity)

func ExplodeHurt(num: float, type: String = "Bomb", playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    parent.Bright()
    return _pipeline.ApplyExplodeHurt(parent, num, type, playSplatAudio, velocity)

func FlagHurt(num: float, damageFlags: int, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    parent.Bright()
    return _pipeline.ApplyFlagHurt(parent, num, damageFlags, playSplatAudio, velocity)

func ProjectileHurt(projectile: TowerDefenseProjectile, projectileConfig: TowerDefenseProjectileConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, isRange: bool = false) -> float:
    parent.Bright()
    return _pipeline.ApplyProjectileHurt(parent, projectile, projectileConfig, playSplatAudio, velocity, isRange)
