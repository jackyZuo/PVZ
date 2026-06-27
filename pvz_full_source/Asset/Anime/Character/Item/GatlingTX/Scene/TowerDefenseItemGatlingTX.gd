@tool
extends TowerDefenseItem

@onready var fireComponent: FireComponent = %FireComponent

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    HitBoxDestroy()
    sprite.SetAnimation("Fire", false)

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 0.5

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "fire":
            for i in 3:
                for j in 5:
                    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
                    var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(randf_range(300, 800), 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), -1, camp, Vector2(0, randf_range(-30, 20)))
                    projectile.projectileBodyNode.scale.x = scale.x
                    projectile.gridPos = gridPos
                await get_tree().create_timer(0.05).timeout

func AnimeCompleted(clip: String) -> void :
    match clip:
        "Fire":
            Destroy()
