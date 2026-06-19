@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent

@export var attack: float = 20.0

@export var fireInterval: float = 1.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

func DestroySet() -> void :
    if instance.hitpoints > 0:
        return
    CreateColdEffect(camp, gridPos)

func Attack() -> void :
    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackAllFlag(attack, TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY)

func ExportVariantSave() -> Dictionary:
    return {"attack": attack, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    attack = data.get("attack", 20.0)
    fireInterval = data.get("fireInterval", 1.0)
