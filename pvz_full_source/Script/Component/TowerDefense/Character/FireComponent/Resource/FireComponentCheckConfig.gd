
@tool
class_name FireComponentCheckConfig extends Resource


@export var projectile: FireComponentProjectileResource

@export var useParentCollision: bool = true:
    set(_useParentCollision):
        useParentCollision = _useParentCollision
        notify_property_list_changed()


@export_storage var collisionFlags = 0




@warning_ignore("unused_parameter")
func CanFire(fireComponent: FireComponent) -> bool:
    return projectile.CanFire(fireComponent, GetCollisionFlags())


func GetProjetile() -> TowerDefenseProjectileCreateData:
    return projectile.GetProjetile()


func GetCollisionFlags() -> int:
    return -1 if useParentCollision else collisionFlags


func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    if !useParentCollision:
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
        "Flag/Collision":
            collisionFlags = value
            return true
    return false


func _get(property: StringName) -> Variant:
    match property:
        "Flag/Collision":
            return collisionFlags
    return null


func _property_can_revert(property: StringName):
    match property:
        "Flag/Collision":
            return true


func _property_get_revert(property: StringName):
    match property:
        "Flag/Collision":
            return 0
