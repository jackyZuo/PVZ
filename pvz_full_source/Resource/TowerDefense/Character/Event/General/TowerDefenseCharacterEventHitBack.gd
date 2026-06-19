@tool
class_name TowerDefenseCharacterEventHitBack extends TowerDefenseCharacterEventBase

@export var length: float = 1.0
@export var time: float = 0.0

func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(pos, target, length, time)

func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(pos, target, length * delta, time * delta)

func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(projectile.global_position, target, length, time)

@warning_ignore("unused_parameter")
static func Run(pos: Vector2, target: TowerDefenseCharacter, _length: float, _time: float) -> void :
    target.BlowBack(_length if target.camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE else - _length, _time)
