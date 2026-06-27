@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent

@onready var fireComponent: FireComponent = %FireComponent

@export var attack: float = 20.0

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval
        attackComponent.attackInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "StarCaltrop":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func ExportVariantSave() -> Dictionary:
    return {"attack": attack, 
        "fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    attack = data.get("attack", 20.0)
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "StarCaltrop")
    fireInterval = data.get("fireInterval", 1.5)


func Attack() -> void :
    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackAllFlag(attack, TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY)
