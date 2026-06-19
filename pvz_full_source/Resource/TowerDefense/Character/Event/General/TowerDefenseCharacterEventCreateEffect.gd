class_name TowerDefenseCharacterEventCreateEffect extends TowerDefenseCharacterEventBase

@export var effectScene: PackedScene

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, effectScene)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, effectScene)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, effectScene)

static func Run(target: TowerDefenseCharacter, _effectScene: PackedScene) -> void :
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var splatEffect = _effectScene.instantiate()
    characterNode.add_child(splatEffect)
    splatEffect.gridPos.y = target.gridPos.y
    splatEffect.global_position = target.global_position - Vector2(0, 20)
