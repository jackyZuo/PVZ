@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 4:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Star":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

var currentFireNum: int = 0
var currentFireTotal: int = 0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

    fireComponent.fireInterval = fireInterval

    sprite.head.animeEvent.connect(AnimeEvent)

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "fire":
            if currentFireNum == 0:
                var dirArray: Array[float] = [30.0, 90.0, 180.0, 270.0, 330.0]
                for i in dirArray.size():
                    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
                    var velocity: Vector2 = 300 * Vector2.from_angle(deg_to_rad(dirArray[i]))
                    var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(i + 1, velocity, fireComponent.fireCheckList[0].projectile.GetProjetile(), instance.collisionFlags + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE, camp, Vector2.ZERO)
                    projectile.projectileSprite.rotation = deg_to_rad(dirArray[i])
                    projectile.projectileBodyNode.scale.x = scale.x
                    projectile.gridPos = gridPos
                    get_tree().create_timer(0.1).timeout.connect(
                        func():
                            if is_instance_valid(projectile):
                                projectile.SetTrack(true)
                    )
                if currentFireTotal != 10:
                    currentFireTotal += 1
            if currentFireTotal == 10:
                if currentFireNum == 0:
                    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
                    var projectileData = TowerDefenseProjectileCreateData.new(&"StarBigCatGatlingPea")
                    projectileData.rangeType = "Boom"
                    projectileData.rangeOverride = true
                    projectileData.rangeSize = Vector2(0.6, 0.6)
                    projectileData.hitPesontage = 1.0
                    var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), projectileData, instance.collisionFlags + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE, camp, Vector2.ZERO)
                    projectile.projectileBodyNode.scale.x = scale.x
                    projectile.gridPos = gridPos
            currentFireNum += 1
            if currentFireNum == fireComponent.fireNum:
                currentFireNum = 0
                if currentFireTotal == 10:
                    currentFireTotal = 0

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "currentFireNum": currentFireNum, 
        "currentFireTotal": currentFireTotal, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 4)
    projectileName = data.get("projectileName", "Star")
    currentFireNum = data.get("currentFireNum", 0)
    currentFireTotal = data.get("currentFireTotal", 0)
    fireInterval = data.get("fireInterval", 1.5)
