class_name TowerDefenseCharacterEventCreateProjectile extends TowerDefenseCharacterEventBase

@export var speed: float = 300
@export var dir: float = 0
@export var projectileData: TowerDefenseProjectileCreateData

var projectileName: String:
    get:
        if projectileData:
            return String(projectileData.projectileName)
        return ""

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    var camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL
    if target.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
    if target.camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
        camp = TowerDefenseEnum.CHARACTER_CAMP.PLANT
    Run(target, 0.0, pos, Vector2.from_angle(deg_to_rad(dir)) * speed, projectileData, target.instance.collisionFlags, camp)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    var camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL
    if target.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
    if target.camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
        camp = TowerDefenseEnum.CHARACTER_CAMP.PLANT
    Run(target, 0.0, pos, Vector2.from_angle(deg_to_rad(dir)) * speed, projectileData, target.instance.collisionFlags, camp)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, projectile.height, projectile.global_position - projectile.velocity.normalized() * 10, Vector2.from_angle(deg_to_rad(dir)) * speed, projectileData, projectile.collisionFlags, projectile.camp)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    var pName = valueDictionary.get("ProjectileName", "")
    if pName != "":
        projectileData = TowerDefenseProjectileCreateData.new(StringName(pName))
    speed = valueDictionary.get("Speed", 300.0)
    dir = valueDictionary.get("Dir", 0.0)

func Export() -> Dictionary:
    return {
        "EventName": "CreateProjectile", 
        "Value": {
            "ProjectileName": projectileName, 
            "Speed": speed, 
            "Dir": dir, 
        }
    }

@warning_ignore("unused_parameter")
static func Run(target: TowerDefenseCharacter, _height: float = 0.0, _pos: Vector2 = Vector2.ZERO, _velocity: Vector2 = Vector2(300, 0), _projectileData: TowerDefenseProjectileCreateData = null, _collisionFlags: int = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT) -> void :
    var projectile = FireComponent.CreateProjectilePosition(null, null, _height, _pos, _velocity, _projectileData, _collisionFlags, camp)
    projectile.checkAll = true
    projectile.projectileBodyNode.rotation = _velocity.angle()
