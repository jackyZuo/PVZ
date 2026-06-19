@tool
extends TowerDefensePlant

@onready var magnetComponent: MagnetComponent = %MagnetComponent
@onready var fireComponent: FireComponent = %FireComponent

@export var drawEvent: Array[TowerDefenseCharacterEventBase]

var projectileList: Array[TowerDefenseProjectile]

var timer: float = 0.0

@export var breakDownTime: float = 15.0:
    set(_breakDownTime):
        breakDownTime = _breakDownTime
        if is_node_ready():
            magnetComponent.breakDownTime = breakDownTime

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if projectileList.size() > 0:
        timer += delta
        for projectileId in projectileList.size():
            var projectile: TowerDefenseProjectile = projectileList[projectileId]
            projectile.global_position = global_position + Vector2(cos(timer * 2.0 + projectileId / 2.0) * 50.0, sin(timer * 1.0 + projectileId / 2.0) * 10.0)
            if sin(timer * 2.0 + projectileId / 2.0) < 0:
                projectile.z_index = z_index + 1
            else:
                projectile.z_index = z_index - 1
        if projectileList.size() > 0:
            var projectile: TowerDefenseProjectile = projectileList.pop_back()
            if projectile.extId >= 0 && projectile._projectileServer:
                projectile._projectileServer.unregister_projectile(projectile.extId)
                projectile.extId = -1
            projectile.SetTrack(false)
            projectile.set_physics_process.call_deferred(true)
            projectile.velocity = Vector2(600, 0) * sign(scale.x)
            projectile.speed = 600
            projectile.hitOver = false
            fireComponent.Refresh()

func DestroySet() -> void :
    magnetComponent.Destroy()
    while projectileList.size() > 0:
        var projectile: TowerDefenseProjectile = projectileList.pop_back()
        if projectile.extId >= 0 && projectile._projectileServer:
            projectile._projectileServer.unregister_projectile(projectile.extId)
            projectile.extId = -1
        projectile.set_physics_process.call_deferred(true)
        projectile.velocity = Vector2(600, 0) * sign(scale.x)
        projectile.speed = 600
        projectile.hitOver = false
        await get_tree().physics_frame

func BreakDown(_armor: TowerDefenseArmorInstance) -> void :
    var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByName(0, Vector2.ZERO, "IceBallTrack", -1, camp, Vector2.ZERO)
    projectile.hitOver = true
    projectile.global_position.y = global_position.y
    projectileList.append(projectile)

func DrawTarget(target: TowerDefenseCharacter) -> void :
    TowerDefenseExplode.CreateExplode(target.global_position, Vector2(1.5, 1.5), drawEvent, [], camp, -1)
    var effect = TowerDefenseManager.CreateEffectParticlesOnce(SNOW_FLAKES, gridPos)
    effect.global_position = target.global_position
    characterNode.add_child(effect)

func ExportVariantSave() -> Dictionary:
    return {
        "timer": timer, 
        "breakDownTime": breakDownTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    timer = data.get("timer", 0.0)
    breakDownTime = data.get("breakDownTime", 15.0)
