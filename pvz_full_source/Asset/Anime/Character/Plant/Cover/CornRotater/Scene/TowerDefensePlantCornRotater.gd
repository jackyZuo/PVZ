@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

var fireNum: int = 4

func FireProjectile(_projectile: TowerDefenseProjectile) -> void :
    for i in fireNum:
        AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
        var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(randf_range(300, 400), 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), -1, camp, Vector2(0, randf_range(-50, 50)))
        projectile.projectileBodyNode.scale.x = scale.x
        projectile.gridPos = gridPos

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 4)
    fireInterval = data.get("fireInterval", 1.5)
