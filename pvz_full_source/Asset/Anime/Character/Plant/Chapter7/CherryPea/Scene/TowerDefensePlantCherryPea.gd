@tool
extends TowerDefensePlant

const TOWER_DEFENSE_PROJECTILE_EFFECT_CHERRY_PEA = preload("uid://c4cl6w0kg0pup")

func Explode() -> void :
    var projectileEffect = TOWER_DEFENSE_PROJECTILE_EFFECT_CHERRY_PEA.instantiate()
    projectileEffect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    projectileEffect.global_position = global_position
    characterNode.add_child(projectileEffect)
