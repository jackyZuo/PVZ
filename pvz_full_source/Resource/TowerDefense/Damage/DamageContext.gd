class_name DamageContext extends RefCounted

enum DamageType{
    HURT, 
    SKIP_INVINCIBLE_HURT, 
    SMASH_HURT, 
    EXPLODE_HURT, 
    PROJECTILE_HURT, 
    HURT_WITH_ATTACK_CONFIG, 
    FLAG_HURT}

var type: DamageType = DamageType.HURT
var target: TowerDefenseCharacter = null
var instance: TowerDefenseCharacterInstance = null
var baseDamage: float = 0.0
var finalDamage: float = 0.0
var damageFlags: int = 0
var collisionFlags: int = 0
var cancelled: bool = false
var penetrated: bool = false
var smash: bool = false
var explode: bool = false
var skipInvincible: bool = false
var hitShield: bool = true
var hitShieldFirst: bool = false
var isRange: bool = false
var explodeType: String = "Bomb"
var projectile: TowerDefenseProjectile = null
var projectileConfig: TowerDefenseProjectileConfig = null
var attackConfig: AttackConfig = null
var playSplatAudio: bool = true
var velocity: Vector2 = Vector2.ZERO
var createDamagePart: bool = true
var projectileHeight: int = -1
var armorPassFlag: bool = false
var resultDamage: float = 0.0
var damageApplied: bool = false
