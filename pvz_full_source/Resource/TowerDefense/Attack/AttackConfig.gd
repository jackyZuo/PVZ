class_name AttackConfig extends Resource

@export var num: float = 20.0

@export var attackScale: float = 1.0
@export var armorAttackScale: float = 1.0

@export_storage var damageFlags: int = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY + TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
@export_storage var collisionFlags: int = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

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
            "name": "Flag/Collision", 
            "type": TYPE_INT, 
            "hint": PROPERTY_HINT_FLAGS, 
            "hint_string": ",".join(TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.keys()), 
        }
    )

    return properties

func _set(property: StringName, value: Variant) -> bool:
    match property:
        "Flag/Damage":
            damageFlags = value
            return true
        "Flag/Collision":
            collisionFlags = value
            return true
    return false

func _get(property: StringName) -> Variant:
    match property:
        "Flag/Damage":
            return damageFlags
        "Flag/Collision":
            return collisionFlags
    return null

func _property_can_revert(property: StringName):
    match property:
        "Flag/Damage":
            return true
        "Flag/Collision":
            return true

func _property_get_revert(property: StringName):
    match property:
        "Flag/Damage":
            return TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY + TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
        "Flag/Collision":
            return TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
