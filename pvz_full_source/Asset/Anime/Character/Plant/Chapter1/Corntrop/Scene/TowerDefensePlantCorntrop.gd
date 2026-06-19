@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent

@export var attack: float = 20.0
@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

func Attack() -> void :
    attackComponent.AttackAllFlag(attack, TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY)
    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
    var projectileName: String = "Kernal"
    var baseDamage: float = 20
    var damageFlags: int = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY | TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
    if randf() < 0.15:
        projectileName = "Butter"
        baseDamage = 40
        damageFlags = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY
    var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
    projectileData.baseDamage = baseDamage
    projectileData.damageFlags = damageFlags
    for i in range(4):
        var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByData(self, null, 0, global_position + Vector2(randf_range(-30, 30), 30), Vector2(randf_range(-20, 20), 0.0), projectileData, -1, camp, Vector2.ZERO)
        projectile.useGravity = true
        projectile.ySpeed = -200.0
        projectile.gridPos = gridPos

func ExportVariantSave() -> Dictionary:
    return {"attack": attack, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    attack = data.get("attack", 20.0)
    fireInterval = data.get("fireInterval", 1.5)
