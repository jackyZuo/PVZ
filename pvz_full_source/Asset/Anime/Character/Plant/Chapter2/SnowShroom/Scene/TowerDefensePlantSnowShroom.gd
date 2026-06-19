@tool
extends TowerDefensePlant

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var projectileName: String = "SnowPea"

var skinName: String = "Default"

func _ready() -> void :
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "Sward"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Sward"
    else:
        skinName = "Default"

func SleepEntered() -> void :
    super.SleepEntered()
    instance.invincible = false

func SleepProcessing(delta: float) -> void :
    super.SleepProcessing(delta)
    instance.invincible = false

func IdleEntered() -> void :
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if CanSleep():
        Sleep()
        return
    super.IdleEntered()
    CreateProjectile()
    HitBoxDestroy()
    instance.invincible = true

func CreateProjectile() -> void :
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var height: float = 600
    var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(StringName(projectileName))
    projectileData.skinName = skinName
    projectileData.baseDamage = 50
    projectileData.damageFlags = TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY
    projectileData.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER
    var projectileConfig: TowerDefenseProjectileConfig = projectileData.BuildConfig()
    for id in range(25):
        for x in range(1, gridNum.x + 1):
            for y in range(1, gridNum.y + 1):
                var _cell = TowerDefenseManager.GetMapCell(Vector2i(x, y))
                var pos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(Vector2i(x, y)) - Vector2(150, 0.0) + Vector2(randf_range( - gridSize.x / 2, gridSize.x / 2), 0.0)
                var heightOffset: float = randf_range(0, 200)
                var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByConfig(null, null, GetGroundHeight(self.global_position.y) + 30 - _cell.GetGroundHeight(), pos, Vector2(randf_range(50, 150), 0.0), projectileConfig, -1, camp)
                projectile.gridPos.y = y
                projectile.z = height + heightOffset
                projectile.ySpeed = 400
                projectile.useFall = true


        await get_tree().create_timer(0.3, false).timeout
    CreateColdEffect(camp, gridPos)
    Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "projectileName": projectileName, 
        "skinName": skinName, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    projectileName = data.get("projectileName", "SnowPea")
    skinName = data.get("skinName", "Default")
