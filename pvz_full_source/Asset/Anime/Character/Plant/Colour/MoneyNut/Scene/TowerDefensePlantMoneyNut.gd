@tool
extends TowerDefensePlant

@onready var magnetCoinComponent: MagnetCoinComponent = %MagnetCoinComponent

var coinNumList: Array[int] = [0, 0, 0]
var over: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    add_to_group("GoldMagnet")

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if magnetCoinComponent.CanCoinDraw():
        state.send_event("ToMagnet")

func MagnetEntered() -> void :
    sprite.SetAnimation("Action", false, 0.2)

@warning_ignore("unused_parameter")
func MagnetProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func MagnetExited() -> void :
    pass

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "action":
            magnetCoinComponent.CoinDraw()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Action":
            Idle()

func CoinGet(num: int) -> void :
    match num:
        10:
            coinNumList[0] += 1
        50:
            coinNumList[1] += 1
        1000:
            coinNumList[2] += 1

func CreateProjectile() -> void :
    var projectile: TowerDefenseProjectile
    if coinNumList[2] > 0:
        for i in coinNumList[2]:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinDiamond")
            _projectileData.baseDamage = 1000
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = FireComponent.CreateProjectilePositionByData(null, null, 0, global_position, Vector2(300, 0), _projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
        coinNumList[2] = 0
    if coinNumList[1] > 0:
        for i in coinNumList[1]:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinGold")
            _projectileData.baseDamage = 500
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = FireComponent.CreateProjectilePositionByData(null, null, 0, global_position, Vector2(300, 0), _projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
        coinNumList[1] = 0
    if coinNumList[0] > 0:
        for i in coinNumList[0]:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinSilver")
            _projectileData.baseDamage = 100
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = FireComponent.CreateProjectilePositionByData(null, null, 0, global_position, Vector2(300, 0), _projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
        coinNumList[0] = 0

func DestroySet() -> void :
    if over:
        return
    over = true
    CreateProjectile()

func ExportVariantSave() -> Dictionary:
    return {
        "coinNumList": coinNumList, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    coinNumList = data.get("coinNumList", [0, 0, 0])
    await get_tree().physics_frame
