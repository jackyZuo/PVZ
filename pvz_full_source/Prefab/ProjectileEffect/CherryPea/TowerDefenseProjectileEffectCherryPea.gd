extends TowerDefenseProjectileEffectBase

var num: int = 10

func _ready() -> void :
    AttackCreate()

func AttackCreate() -> void :
    for x in num:
        for i in 36:
            var dir: Vector2 = Vector2.from_angle(deg_to_rad(i * 10))
            var projectile = FireComponent.CreateProjectilePositionByData(null, null, 10, global_position, dir * randf_range(200.0, 800.0), TowerDefenseProjectileCreateData.new(&"Pea"), -1, camp)
            projectile.checkAll = true
            projectile.projectileBodyNode.rotation_degrees = i * 10
        await get_tree().physics_frame
