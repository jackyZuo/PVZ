class_name TowerDefenseProjectileMethod extends Resource

var projectile: TowerDefenseProjectile

func _init() -> void :
    pass

@warning_ignore("unused_parameter")
func Ready() -> void :
    pass

@warning_ignore("unused_parameter")
func Process(delta: float) -> void :
    pass

@warning_ignore("unused_parameter")
func Destroy() -> void :
    pass

@warning_ignore("unused_parameter")
func HitTarget(target: TowerDefenseCharacter) -> void :
    pass

@warning_ignore("unused_parameter")
func SetDamage(damageBase: float, target: TowerDefenseCharacter) -> float:
    return damageBase

@warning_ignore("unused_parameter")
func Change(projectileName: StringName, changeProjectileName: StringName, changeCharacter: TowerDefenseCharacter) -> void :
    pass
