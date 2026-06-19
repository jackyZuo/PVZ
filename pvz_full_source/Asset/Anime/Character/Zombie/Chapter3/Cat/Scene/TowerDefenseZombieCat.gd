@tool
extends TowerDefenseZombie

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Spike":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_whitewater"], true)

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    if global_position.x > groundRight:
        sprite.timeScale = timeScale * walkSpeedScale * 2.0
    else:
        sprite.timeScale = timeScale * walkSpeedScale
    if !sprite.pause && attackComponent.CanAttack():
        ChangeLine()

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 3.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "fire":
            if nearDie || die:
                return
            if global_position.x <= groundRight:
                await get_tree().physics_frame
                if fireComponent.CanFireByData(fireComponent.fireCheckList[0].projectile.GetProjetile(), TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM):
                    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
                    var projectile: TowerDefenseProjectile
                    projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM, camp, Vector2.ZERO)
                    projectile.projectileBodyNode.rotate(PI * scale.x)
                    projectile.gridPos = gridPos
