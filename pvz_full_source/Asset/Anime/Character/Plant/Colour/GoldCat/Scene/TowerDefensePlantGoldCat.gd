@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
@onready var timerComponent: TimerComponent = %TimerComponent

@export var fireInterval: float = 3.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "CoinGold":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause:
                CreateProjectile()
            timerComponent.Run("Spawn", 30.0)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 30.0)

func CreateProjectile() -> void :
    AudioManager.AudioPlay("Prize", AudioManagerEnum.TYPE.SFX)
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var height: float = 600
    for x in range(1, gridNum.x + 1):
        var y = randi_range(1, gridNum.y)
        var _cell = TowerDefenseManager.GetMapCell(Vector2i(x, y))
        var pos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(Vector2i(x, y)) - Vector2(150, 0.0) + Vector2(randf_range( - gridSize.x / 2, gridSize.x / 2), 0.0)
        var heightOffset: float = randf_range(0, 200)
        var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinGold")
        projectileData.baseDamage = 500
        var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByData(null, null, GetGroundHeight(self.global_position.y) + 30 - _cell.GetGroundHeight(), pos, Vector2(randf_range(50, 100), 0.0), projectileData, -1, camp)
        projectile.gridPos.y = y
        projectile.z = height + heightOffset
        projectile.ySpeed = 400
        projectile.useFall = true
        if !projectile.landOver.is_connected(LandOver):
            projectile.landOver.connect(LandOver)

func LandOver(pos2: Vector2, gridPos2: Vector2i) -> void :
    var projectileData2: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinGold")
    projectileData2.baseDamage = 500
    projectileData2.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
    var projectile2: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByData(null, null, 0.0, pos2, Vector2(300.0, 0.0), projectileData2, -1, camp)
    projectile2.gridPos = gridPos2

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "CoinGold")
    fireInterval = data.get("fireInterval", 3.0)
