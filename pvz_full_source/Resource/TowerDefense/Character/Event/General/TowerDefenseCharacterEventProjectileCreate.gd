class_name TowerDefenseCharacterEventProjectileCreate extends TowerDefenseCharacterEventBase

@export var projectileData: TowerDefenseProjectileCreateData
@export var createNum: int = 8
@export var createGridToRange: Vector4i = Vector4(-1, -1, 1, 1)
@export var createSpeedToRange: Vector2 = Vector2(-100, 100)
@export var useFall: bool = false

var projectileName: String:
    get:
        if projectileData:
            return String(projectileData.projectileName)
        return ""

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, projectileData, createNum, createGridToRange, createSpeedToRange, useFall)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, projectileData, createNum, createGridToRange, createSpeedToRange, useFall)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, projectileData, createNum, createGridToRange, createSpeedToRange, useFall, projectile.collisionFlags, projectile.camp)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    var pName = valueDictionary.get("ProjectileName", "")
    if pName != "":
        projectileData = TowerDefenseProjectileCreateData.new(StringName(pName))
    createNum = valueDictionary.get("CreateNum", "")
    createGridToRange = valueDictionary.get("CreateGridToRange", Vector4i(-1, -1, 1, 1))
    createSpeedToRange = valueDictionary.get("CreateSpeedToRange", Vector2(-100, 100))
    useFall = valueDictionary.get("useFall", false)


func Export() -> Dictionary:
    return {
        "EventName": "ProjectileCreate", 
        "Value": {
            "ProjectileName": projectileName, 
            "CreateNum": createNum, 
            "CreateSpeedToRange": createSpeedToRange, 
            "CreateGridToRange": createGridToRange, 
            "useFall": useFall
        }
    }

static func Run(target: TowerDefenseCharacter, _projectileData: TowerDefenseProjectileCreateData, _createNum: int = 8, _createGridToRange: Vector4i = Vector4i(-1, -1, 1, 1), _createToRange: Vector2 = Vector2(-100, 100), _useFall: bool = false, _collisionFlags: int = -1, _camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.ALL) -> void :
    for i in _createNum:
        var offsetGrid = Vector2i(randi_range(_createGridToRange.x, _createGridToRange.z), randi_range(_createGridToRange.y, _createGridToRange.w))
        var scatterVelocity: Vector2 = Vector2(randf_range(_createToRange.x, _createToRange.y), offsetGrid.y * 100)
        var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePosition(null, null, 0, target.global_position, scatterVelocity, _projectileData, _collisionFlags, _camp)
        if _useFall:
            projectile.useFall = true
            projectile.z = 600
            projectile.ySpeed = 400
        else:
            projectile.useGravity = true
            projectile.gravity = 980
            projectile.ySpeed = -800.0
        projectile.catapultOpen = false
        projectile.isGround = false
        projectile.velocity = scatterVelocity / 1.5
        projectile.gridPos = target.gridPos + offsetGrid
