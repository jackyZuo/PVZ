class_name ShovelEventCreateProjectileConfig extends ShovelEventConfig

@export var everyNum: int = 10
@export var projecileName: String
@export var projectileBaseDamage: float = 20

func Execute(character: TowerDefenseCharacter) -> void :
    var height: float = character.GetGroundHeight(character.global_position.y)
    for i in floor(character.cost / everyNum):
        var heightOffset: float = randf_range(-10, 40)
        var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projecileName))
        projectileData.baseDamage = projectileBaseDamage
        var projectile = FireComponent.CreateProjectilePositionByData(character, null, height + heightOffset - 20, character.global_position + Vector2(randf_range(-10, 10), -20), Vector2(300.0, 0.0), projectileData, -1, character.camp)
        projectile.gridPos.y = character.gridPos.y
