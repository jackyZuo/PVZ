
@tool
class_name ChangeProjectileStateComponent extends ComponentBase


@export var checkArea: Area2D

@export var target: TowerDefenseCharacter

@export var followCamp: bool = true

@export_storage var damageFlags: int = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY + TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD

@export_storage var fireMethodFlags: int = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER


var parent: TowerDefenseCharacter


func GetName() -> String:
    return "ChangeProjectileStateComponent"


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
    return false


func _get(property: StringName) -> Variant:
    match property:
        "Flag/Damage":
            return damageFlags
        "Flag/FireMethod":
            return fireMethodFlags
    return null


func _property_can_revert(property: StringName):
    match property:
        "Flag/Damage":
            return true
        "Flag/FireMethod":
            return true


func _property_get_revert(property: StringName):
    match property:
        "Flag/Damage":
            return TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY + TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
        "Flag/FireMethod":
            return TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER


func _ready():
    if Engine.is_editor_hint():
        return
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    checkArea.area_entered.connect(ChangeProjectile)



func ChangeProjectile(area: Area2D):
    if !alive:
        return
    if parent.die || parent.nearDie:
        return
    var projectile = area.get_parent()
    if !(projectile is TowerDefenseProjectile):
        return
    if followCamp:
        if projectile.camp == parent.camp:
            return
    projectile.damageFlags = damageFlags
    if fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK:
        var trackTarget: TowerDefenseCharacter = target if is_instance_valid(target) else parent
        projectile.SetTrack(true)
        projectile.target = trackTarget
        projectile.magneticTarget = trackTarget
