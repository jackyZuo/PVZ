@tool
class_name TowerDefenseProjectileCreateData extends Resource

@export var projectileName: StringName
@export var skinName: StringName = &"Default"
@export var size: Vector2 = Vector2(28, 28): set = SetSize
@export var scale: Vector2 = Vector2(1, 1): set = SetScale
@export var baseDamage: float = -1.0: set = SetBaseDamage
@export_storage var hitChestsScale: float = 1.0: set = SetHitChestsScale
@export_storage var hitNutScale: float = 1.0: set = SetHitNutScale
@export_storage var hitFrozenScale: float = 1.0: set = SetHitFrozenScale
@export_storage var damageFlags: int = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY + TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD: set = SetDamageFlags
@export_storage var collisionFlags: int = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE: set = SetCollisionFlags
@export_storage var fireMethodFlags: int = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER: set = SetFireMethodFlags
@export_storage var catapultHeight: float = 300.0: set = SetCatapultHeight
@export_storage var penetrateNum: int = 3: set = SetPenetrateNum
@export_storage var penetrateOverBack: bool = true: set = SetPenetrateOverBack
@export_storage var backOutGround: bool = true: set = SetBackOutGround
@export_storage var backDuration: float = 1.0: set = SetBackDuration
@export_storage var rotateFollowVelocity: bool = false: set = SetRotateFollowVelocity
var overrideHitChestsScale: bool = false
var overrideHitNutScale: bool = false
var overrideHitFrozenScale: bool = false
var overrideCatapultHeight: bool = false
var overridePenetrateNum: bool = false
var overridePenetrateOverBack: bool = false
var overrideBackOutGround: bool = false
var overrideBackDuration: bool = false
var overrideRotateFollowVelocity: bool = false
@export var rangeOverride: bool = false: set = SetRangeOverride
@export var rangeType: String = "Default": set = SetRangeType
@export var useRange: bool = false: set = SetUseRange
@export var rangeSize: Vector2 = Vector2(0.5, 0.5): set = SetRangeSize
@export var hitPesontage: float = 0.25: set = SetHitPesontage
@export var overrideHitTargetEvent: bool = false: set = SetOverrideHitTargetEvent
@export var overrideHitCharacterEvent: bool = false: set = SetOverrideHitCharacterEvent
@export var overrideHitGroundEvent: bool = false: set = SetOverrideHitGroundEvent
@export var hitTargetEventList: Array[TowerDefenseCharacterEventBase] = []
@export var hitCharacterEventList: Array[TowerDefenseCharacterEventBase] = []
@export var hitGroundEventList: Array[TowerDefenseCharacterEventBase] = []
@export var methods: Array[TowerDefenseProjectileMethod] = []

func _init(_projectileName: StringName = &"") -> void :
    projectileName = _projectileName

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    properties.append(
        {
            "name": "Flag/Damage", 
            "type": TYPE_INT, 
            "hint": PROPERTY_HINT_FLAGS, 
            "hint_string": ",".join(TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.keys()), 
        }
    )
    properties.append(
        {
            "name": "Flag/FireMethod", 
            "type": TYPE_INT, 
            "hint": PROPERTY_HINT_FLAGS, 
            "hint_string": ",".join(TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.keys()), 
        }
    )
    properties.append(
        {
            "name": "Flag/Collision", 
            "type": TYPE_INT, 
            "hint": PROPERTY_HINT_FLAGS, 
            "hint_string": ",".join(TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.keys()), 
        }
    )
    properties.append(
        {
            "name": "Override/Hit Chests Scale", 
            "type": TYPE_BOOL
        }
    )
    if overrideHitChestsScale:
        properties.append(
            {
                "name": "HitChests/Scale", 
                "type": TYPE_FLOAT
            }
        )
    properties.append(
        {
            "name": "Override/Hit Nut Scale", 
            "type": TYPE_BOOL
        }
    )
    if overrideHitNutScale:
        properties.append(
            {
                "name": "HitNut/Scale", 
                "type": TYPE_FLOAT
            }
        )
    properties.append(
        {
            "name": "Override/Hit Frozen Scale", 
            "type": TYPE_BOOL
        }
    )
    if overrideHitFrozenScale:
        properties.append(
            {
                "name": "HitFrozen/Scale", 
                "type": TYPE_FLOAT
            }
        )
    properties.append(
        {
            "name": "Override/Catapult Height", 
            "type": TYPE_BOOL
        }
    )
    var catpultFlag: bool = fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT
    if overrideCatapultHeight && catpultFlag:
        properties.append(
            {
                "name": "Catapult/Height", 
                "type": TYPE_FLOAT
            }
        )
    properties.append(
        {
            "name": "Override/Penetrate Num", 
            "type": TYPE_BOOL
        }
    )
    var penetrateFlag: bool = fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.PENETRATE
    if overridePenetrateNum && penetrateFlag:
        properties.append(
            {
                "name": "Penetrate/Num", 
                "type": TYPE_INT
            }
        )
    properties.append(
        {
            "name": "Override/Penetrate Over Back", 
            "type": TYPE_BOOL
        }
    )
    var backFlag: bool = fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.BACK
    if overridePenetrateOverBack && penetrateFlag && backFlag:
        properties.append(
            {
                "name": "Penetrate/OverBack", 
                "type": TYPE_BOOL
            }
        )
    properties.append(
        {
            "name": "Override/Back Out Ground", 
            "type": TYPE_BOOL
        }
    )
    if overrideBackOutGround && backFlag:
        properties.append(
            {
                "name": "Back/OutOfGround", 
                "type": TYPE_BOOL
            }
        )
    properties.append(
        {
            "name": "Override/Back Duration", 
            "type": TYPE_BOOL
        }
    )
    if overrideBackDuration && backFlag:
        properties.append(
            {
                "name": "Back/Duration", 
                "type": TYPE_FLOAT
            }
        )
    properties.append(
        {
            "name": "Override/Rotate Follow Velocity", 
            "type": TYPE_BOOL
        }
    )
    if overrideRotateFollowVelocity:
        properties.append(
            {
                "name": "Rotate/FollowVelocity", 
                "type": TYPE_BOOL
            }
        )
    return properties

func _set(property: StringName, value: Variant) -> bool:
    match property:
        "Flag/Damage":
            damageFlags = value
            return true
        "Flag/FireMethod":
            fireMethodFlags = value
            notify_property_list_changed()
            return true
        "Flag/Collision":
            collisionFlags = value
            return true
        "Override/Hit Chests Scale":
            overrideHitChestsScale = value
            notify_property_list_changed()
            return true
        "Override/Hit Nut Scale":
            overrideHitNutScale = value
            notify_property_list_changed()
            return true
        "Override/Hit Frozen Scale":
            overrideHitFrozenScale = value
            notify_property_list_changed()
            return true
        "Override/Catapult Height":
            overrideCatapultHeight = value
            notify_property_list_changed()
            return true
        "Override/Penetrate Num":
            overridePenetrateNum = value
            notify_property_list_changed()
            return true
        "Override/Penetrate Over Back":
            overridePenetrateOverBack = value
            notify_property_list_changed()
            return true
        "Override/Back Out Ground":
            overrideBackOutGround = value
            notify_property_list_changed()
            return true
        "Override/Back Duration":
            overrideBackDuration = value
            notify_property_list_changed()
            return true
        "Override/Rotate Follow Velocity":
            overrideRotateFollowVelocity = value
            notify_property_list_changed()
            return true
        "HitChests/Scale":
            hitChestsScale = value
            return true
        "HitNut/Scale":
            hitNutScale = value
            return true
        "HitFrozen/Scale":
            hitFrozenScale = value
            return true
        "Catapult/Height":
            catapultHeight = value
            return true
        "Penetrate/Num":
            penetrateNum = value
            return true
        "Penetrate/OverBack":
            penetrateOverBack = value
            return true
        "Back/OutOfGround":
            backOutGround = value
            return true
        "Back/Duration":
            backDuration = value
            return true
        "Rotate/FollowVelocity":
            rotateFollowVelocity = value
            return true
    return false

func _get(property: StringName) -> Variant:
    match property:
        "Flag/Damage":
            return damageFlags
        "Flag/FireMethod":
            return fireMethodFlags
        "Flag/Collision":
            return collisionFlags
        "Override/Hit Chests Scale":
            return overrideHitChestsScale
        "Override/Hit Nut Scale":
            return overrideHitNutScale
        "Override/Hit Frozen Scale":
            return overrideHitFrozenScale
        "Override/Catapult Height":
            return overrideCatapultHeight
        "Override/Penetrate Num":
            return overridePenetrateNum
        "Override/Penetrate Over Back":
            return overridePenetrateOverBack
        "Override/Back Out Ground":
            return overrideBackOutGround
        "Override/Back Duration":
            return overrideBackDuration
        "Override/Rotate Follow Velocity":
            return overrideRotateFollowVelocity
        "HitChests/Scale":
            return hitChestsScale
        "HitNut/Scale":
            return hitNutScale
        "HitFrozen/Scale":
            return hitFrozenScale
        "Catapult/Height":
            return catapultHeight
        "Penetrate/Num":
            return penetrateNum
        "Penetrate/OverBack":
            return penetrateOverBack
        "Back/OutOfGround":
            return backOutGround
        "Back/Duration":
            return backDuration
        "Rotate/FollowVelocity":
            return rotateFollowVelocity
    return null

func _property_can_revert(property: StringName):
    match property:
        "Flag/Damage":
            return true
        "Flag/FireMethod":
            return true
        "Flag/Collision":
            return true
        "Override/Hit Chests Scale":
            return true
        "Override/Hit Nut Scale":
            return true
        "Override/Hit Frozen Scale":
            return true
        "Override/Catapult Height":
            return true
        "Override/Penetrate Num":
            return true
        "Override/Penetrate Over Back":
            return true
        "Override/Back Out Ground":
            return true
        "Override/Back Duration":
            return true
        "Override/Rotate Follow Velocity":
            return true
        "HitChests/Scale":
            return true
        "HitNut/Scale":
            return true
        "HitFrozen/Scale":
            return true
        "Catapult/Height":
            return true
        "Penetrate/Num":
            return true
        "Penetrate/OverBack":
            return true
        "Back/OutOfGround":
            return true
        "Back/Duration":
            return true
        "Rotate/FollowVelocity":
            return true

func _property_get_revert(property: StringName):
    match property:
        "Flag/Damage":
            return TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY + TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
        "Flag/FireMethod":
            return TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER
        "Flag/Collision":
            return TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
        "Override/Hit Chests Scale":
            return false
        "Override/Hit Nut Scale":
            return false
        "Override/Hit Frozen Scale":
            return false
        "Override/Catapult Height":
            return false
        "Override/Penetrate Num":
            return false
        "Override/Penetrate Over Back":
            return false
        "Override/Back Out Ground":
            return false
        "Override/Back Duration":
            return false
        "Override/Rotate Follow Velocity":
            return false
        "HitChests/Scale":
            return 1.0
        "HitNut/Scale":
            return 1.0
        "HitFrozen/Scale":
            return 1.0
        "Catapult/Height":
            return 400.0
        "Penetrate/Num":
            return 3
        "Penetrate/OverBack":
            return true
        "Back/OutOfGround":
            return true
        "Back/Duration":
            return 1.0
        "Rotate/FollowVelocity":
            return false

func SetBaseDamage(_baseDamage: float) -> void :
    baseDamage = _baseDamage

func SetSize(_size: Vector2) -> void :
    size = _size

func SetScale(_scale: Vector2) -> void :
    scale = _scale

func SetHitChestsScale(_hitChestsScale: float) -> void :
    hitChestsScale = _hitChestsScale

func SetHitNutScale(_hitNutScale: float) -> void :
    hitNutScale = _hitNutScale

func SetHitFrozenScale(_hitFrozenScale: float) -> void :
    hitFrozenScale = _hitFrozenScale

func SetDamageFlags(_damageFlags: int) -> void :
    damageFlags = _damageFlags

func SetCollisionFlags(_collisionFlags: int) -> void :
    collisionFlags = _collisionFlags

func SetFireMethodFlags(_fireMethodFlags: int) -> void :
    fireMethodFlags = _fireMethodFlags

func SetCatapultHeight(_catapultHeight: float) -> void :
    catapultHeight = _catapultHeight

func SetPenetrateNum(_penetrateNum: int) -> void :
    penetrateNum = _penetrateNum

func SetPenetrateOverBack(_penetrateOverBack: bool) -> void :
    penetrateOverBack = _penetrateOverBack

func SetBackOutGround(_backOutGround: bool) -> void :
    backOutGround = _backOutGround

func SetBackDuration(_backDuration: float) -> void :
    backDuration = _backDuration

func SetRotateFollowVelocity(_rotateFollowVelocity: bool) -> void :
    rotateFollowVelocity = _rotateFollowVelocity

func SetRangeOverride(_rangeOverride: bool) -> void :
    rangeOverride = _rangeOverride

func SetRangeType(_rangeType: String) -> void :
    rangeType = _rangeType

func SetUseRange(_useRange: bool) -> void :
    useRange = _useRange

func SetRangeSize(_rangeSize: Vector2) -> void :
    rangeSize = _rangeSize

func SetHitPesontage(_hitPesontage: float) -> void :
    hitPesontage = _hitPesontage

func SetOverrideHitTargetEvent(_overrideHitTargetEvent: bool) -> void :
    overrideHitTargetEvent = _overrideHitTargetEvent

func SetOverrideHitCharacterEvent(_overrideHitCharacterEvent: bool) -> void :
    overrideHitCharacterEvent = _overrideHitCharacterEvent

func SetOverrideHitGroundEvent(_overrideHitGroundEvent: bool) -> void :
    overrideHitGroundEvent = _overrideHitGroundEvent

func BuildConfig() -> TowerDefenseProjectileConfig:
    var data: TowerDefenseProjectileData = TowerDefenseProjectileRegistry.GetProjectile(projectileName)
    if data:
        var config: TowerDefenseProjectileConfig = TowerDefenseProjectileConfig.new()

        config.damageFlags = damageFlags
        config.collisionFlags = collisionFlags
        config.fireMethodFlags = fireMethodFlags
        config.name = data.name
        config.skinName = skinName
        config.size = data.size
        config.scale = data.scale
        config.projectileScene = data.projectileScene
        config.splatAudio = data.splatAudio
        config.splatScene = data.splatScene
        config.hitEffect = data.hitEffect
        config.hitTargetEventList = data.hitTargetEventList
        config.hitCharacterEventList = data.hitCharacterEventList
        config.hitGroundEventList = data.hitGroundEventList
        config.blockHurt = data.blockHurt
        config.rotateFollowVelocity = data.rotateFollowVelocity
        config.rotateScale = data.rotateScale
        config.hitBody = data.hitBody
        config.rangeType = data.rangeType
        config.useRange = data.useRange
        config.rangeSize = data.rangeSize
        config.hitPesontage = data.hitPesontage
        config.baseDamage = data.baseDamage

        var baseConfig: TowerDefenseProjectileConfig = TowerDefenseManager.GetProjectileConfig(String(projectileName))
        if baseConfig:
            config.penetrateNum = baseConfig.penetrateNum
            config.penetrateOverBack = baseConfig.penetrateOverBack
            config.backOutGround = baseConfig.backOutGround
            config.backDuration = baseConfig.backDuration
            config.catapultHeight = baseConfig.catapultHeight
            config.splatSceneType = baseConfig.splatSceneType
            config.hitChestsScale = baseConfig.hitChestsScale
            config.hitNutScale = baseConfig.hitNutScale
            config.hitFrozenScale = baseConfig.hitFrozenScale
            if !config.projectileScene:
                config.projectileScene = baseConfig.projectileScene
            if !config.splatScene:
                config.splatScene = baseConfig.splatScene
            penetrateNum = baseConfig.penetrateNum
            penetrateOverBack = baseConfig.penetrateOverBack
            backOutGround = baseConfig.backOutGround
            backDuration = baseConfig.backDuration
            catapultHeight = baseConfig.catapultHeight
            hitChestsScale = baseConfig.hitChestsScale
            hitNutScale = baseConfig.hitNutScale
            hitFrozenScale = baseConfig.hitFrozenScale
            rotateFollowVelocity = baseConfig.rotateFollowVelocity
        if TowerDefenseProjectileRegistry.HasProjectileSkin(projectileName, skinName):
            var projectileScene: PackedScene = TowerDefenseProjectileRegistry.GetProjectileSkinProjectileScene(projectileName, skinName)
            if projectileScene:
                config.projectileScene = projectileScene
            var splatScene: PackedScene = TowerDefenseProjectileRegistry.GetProjectileSkinSplatScene(projectileName, skinName)
            if splatScene:
                config.splatScene = splatScene
        _ApplyOverride(config)
        return config
    var fallbackConfig: TowerDefenseProjectileConfig = TowerDefenseManager.GetProjectileConfig(String(projectileName)).duplicate(true)
    if fallbackConfig:
        _ApplyOverride(fallbackConfig)
        return fallbackConfig
    return null

func _ApplyOverride(config: TowerDefenseProjectileConfig) -> void :
    if baseDamage >= 0:
        config.baseDamage = baseDamage
    config.size = size
    config.scale = scale
    if overrideHitChestsScale:
        config.hitChestsScale = hitChestsScale
    if overrideHitNutScale:
        config.hitNutScale = hitNutScale
    if overrideHitFrozenScale:
        config.hitFrozenScale = hitFrozenScale
    if overrideCatapultHeight:
        config.catapultHeight = catapultHeight
    if overridePenetrateNum:
        config.penetrateNum = penetrateNum
    if overridePenetrateOverBack:
        config.penetrateOverBack = penetrateOverBack
    if overrideBackOutGround:
        config.backOutGround = backOutGround
    if overrideBackDuration:
        config.backDuration = backDuration
    if overrideRotateFollowVelocity:
        config.rotateFollowVelocity = rotateFollowVelocity
    if methods.size() > 0:
        config.methods = methods
    if rangeOverride:
        config.rangeType = rangeType
        config.useRange = useRange
        config.rangeSize = rangeSize
        config.hitPesontage = hitPesontage
    if overrideHitTargetEvent:
        config.hitTargetEventList = hitTargetEventList
    if overrideHitCharacterEvent:
        config.hitCharacterEventList = hitCharacterEventList
    if overrideHitGroundEvent:
        config.hitGroundEventList = hitGroundEventList
