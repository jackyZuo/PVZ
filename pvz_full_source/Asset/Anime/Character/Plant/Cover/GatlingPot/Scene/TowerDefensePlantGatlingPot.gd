@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval
        fireComponent.onlyEmitSignal = fireInterval < 0.5

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName


func FireProjectile(_projectile: TowerDefenseProjectile) -> void :
    if fireInterval < 0.5:
        for i in range(floor((0.4 - fireInterval) / 0.1) * 2.0):
            AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
            var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(randf_range(300, 800), 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), -1, camp, Vector2(0, randf_range(-30, 20)))
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Pea")
    fireInterval = data.get("fireInterval", 1.5)
