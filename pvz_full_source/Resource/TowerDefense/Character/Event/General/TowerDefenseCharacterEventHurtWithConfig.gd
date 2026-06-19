@tool
class_name TowerDefenseCharacterEventHurtWithConfig extends TowerDefenseCharacterEventBase

@export var attackConfig: AttackConfig = AttackConfig.new()
@export var playSplatAudio: bool = true

func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(pos, target, attackConfig, playSplatAudio)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(pos, target, attackConfig, playSplatAudio)

func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(projectile.global_position, target, attackConfig, playSplatAudio)

@warning_ignore("unused_parameter")
static func Run(pos: Vector2, target: TowerDefenseCharacter, _attackConfig: AttackConfig, _playSplatAudio: bool = true) -> void :
    target.HurtWithAttackConfig(_attackConfig, _playSplatAudio)
    target.AttackDeal(null, "Default", _attackConfig.num)
