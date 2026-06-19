class_name TowerDefenseProjectileChangeData extends RefCounted

var changeList: Array[StringName]
var changeToProjectile: Dictionary[StringName, StringName]

func AddChange(projectileName: StringName, toProjectileName: StringName) -> void :
    changeToProjectile[projectileName] = toProjectileName
    changeList.append(projectileName)

func GetChange(projectileName: StringName) -> StringName:
    if !HasChange(projectileName):
        return &""
    return changeToProjectile[projectileName]

func HasChange(projectileName: StringName) -> bool:
    return changeList.has(projectileName)

func HasChangeTarget(projectileName: StringName) -> bool:
    return changeToProjectile.values().has(projectileName)

func IsEmpty() -> bool:
    return changeList.is_empty()
