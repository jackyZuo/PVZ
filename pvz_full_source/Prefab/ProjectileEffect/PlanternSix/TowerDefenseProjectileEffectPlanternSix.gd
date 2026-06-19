extends TowerDefenseProjectileEffectBase

var projectileList: Array[TowerDefenseProjectile]

var timer: float = 0.0
var over: bool = false

func _ready() -> void :
    AttackCreate()

func _physics_process(delta: float) -> void :
    var freshList: Array[TowerDefenseProjectile] = []
    for projectile in projectileList:
        if !is_instance_valid(projectile):
            continue
        if !projectile.is_inside_tree():
            continue
        if projectile.trackOpen:
            projectile.speed = 300
            continue
        freshList.append(projectile)
    projectileList = freshList

    if over:
        if projectileList.size() <= 0:
            queue_free()
            return

    timer += delta
    var size: int = projectileList.size()
    var firstSize: int = floor(projectileList.size() / 2.0)
    var scondSize: int = size - firstSize
    for i in firstSize:
        var process: float = TAU / firstSize * i + timer * 5.0
        var pos = global_position + Vector2(cos(process) * 30, sin(process) * 30)
        var projectile: TowerDefenseProjectile = projectileList[i]
        projectile.projectileBodyNode.rotation = lerp_angle(projectile.projectileBodyNode.rotation, (pos - projectile.global_position).angle(), 5.0 * delta)
        projectile.global_position = lerp(projectile.global_position, pos, 5.0 * delta)
    for i in scondSize:
        var process: float = TAU / scondSize * i + timer
        var pos = global_position + Vector2(cos(process) * 60, sin(process) * 60)
        var projectile: TowerDefenseProjectile = projectileList[firstSize + i]
        projectile.projectileBodyNode.rotation = lerp_angle(projectile.projectileBodyNode.rotation, (pos - projectile.global_position).angle(), 5.0 * delta)
        projectile.global_position = lerp(projectile.global_position, pos, 5.0 * delta)

func AttackCreate() -> void :
    for i in 10:
        for j in 6:
            var dir = 0
            var projectileName = "Pea"
            match j:
                0:
                    dir = 60
                    projectileName = "Pea"
                1:
                    dir = 0
                    projectileName = "FirePea"
                2:
                    dir = -60
                    projectileName = "SnowPea"
                3:
                    dir = 120
                    projectileName = "Pea"
                4:
                    dir = 180
                    projectileName = "FirePea"
                5:
                    dir = 240
                    projectileName = "SnowPea"
            var projectile = FireComponent.CreateProjectilePositionByData(null, null, 30.0, global_position, Vector2.ZERO, TowerDefenseProjectileCreateData.new(StringName(projectileName)), -1, camp)
            projectile.checkAll = true
            projectile.gridPos = gridPos
            var _global_position = global_position
            var _dir = dir
            projectile.tree_exited.connect(
                func():
                    projectileList.erase(projectile)
            )
            projectile.get_tree().create_timer(2.0, false).timeout.connect(
                func():
                    if !is_instance_valid(projectile):
                        return
                    projectileList.erase(projectile)
                    if projectile.extId >= 0 && projectile._projectileServer:
                        projectile._projectileServer.unregister_projectile(projectile.extId)
                        projectile.extId = -1
                    projectile.moveTween = projectile.create_tween()
                    projectile.moveTween.set_ease(Tween.EASE_OUT)
                    projectile.moveTween.set_trans(Tween.TRANS_QUART)
                    projectile.moveTween.set_parallel(true)
                    projectile.moveTween.tween_property(projectile, ^"global_position", _global_position, 0.1)
                    projectile.moveTween.tween_property(projectile.projectileBodyNode, ^"rotation", deg_to_rad(_dir), 0.1)
                    projectile.velocity = Vector2.from_angle(deg_to_rad(_dir)) * 300.0
                    projectile.speed = projectile.velocity.length()
                    projectile.set_physics_process.call_deferred(true)
            )
            projectileList.append(projectile)
        await get_tree().create_timer(0.1, false).timeout

    over = true
