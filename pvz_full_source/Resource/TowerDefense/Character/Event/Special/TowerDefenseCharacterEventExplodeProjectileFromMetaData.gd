class_name TowerDefenseCharacterEventExplodeProjectileFromMetaData extends TowerDefenseCharacterEventBase

@export var speed: float = 300

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    pass

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    pass

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, projectile.metaData, speed, projectile.global_position, projectile.height, projectile.collisionFlags, projectile.camp)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    pass

func Export() -> Dictionary:
    return {
        "EventName": "SnowBallSpawn", 
        "Value": {}
    }

static func Run(_target: TowerDefenseCharacter, _metaData: Variant, _speed: float, _pos: Vector2, _height: float, _collisionFlags: int = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT) -> void :
    if !(_metaData is Array):
        return
    for projectileConfig in _metaData:
        var _velocity = Vector2.from_angle(randf() * 2 * PI) * _speed
        var projectile = FireComponent.CreateProjectilePositionWithConfig(null, null, _height, _pos, _velocity, projectileConfig, _collisionFlags, camp)
        projectile.checkAll = true
        projectile.projectileBodyNode.rotation = _velocity.angle()
