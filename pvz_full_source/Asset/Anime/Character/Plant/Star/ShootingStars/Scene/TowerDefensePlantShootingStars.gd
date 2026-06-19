@tool
extends TowerDefensePlant

var projectileName: String = "Star"

func _ready() -> void :
    super._ready()

func IdleEntered() -> void :
    super.IdleEntered()
    if Engine.is_editor_hint():
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return

    CreateProjectile()
    HitBoxDestroy()
    instance.invincible = true

func CreateProjectile() -> void :
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var height: float = 600
    for id in range(25):
        for x in range(1, gridNum.x + 1):
            for y in range(1, gridNum.y + 1):
                var _cell = TowerDefenseManager.GetMapCell(Vector2i(x, y))
                var pos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(Vector2i(x, y)) - Vector2(150, 0.0) + Vector2(randf_range( - gridSize.x / 2, gridSize.x / 2), 0.0)
                var heightOffset: float = randf_range(0, 200)
                var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName("BigStar" if randf() < 0.05 else projectileName))
                var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByData(null, null, GetGroundHeight(self.global_position.y) + 30 - _cell.GetGroundHeight(), pos, Vector2(randf_range(50, 150), 0.0), _projectileData, -1, camp)
                projectile.gridPos.y = y
                projectile.z = height + heightOffset
                projectile.ySpeed = 400
                projectile.useFall = true


        await get_tree().create_timer(0.3, false).timeout
    Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "projectileName": projectileName, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    projectileName = data.get("projectileName", "Star")
