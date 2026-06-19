@tool
extends TowerDefensePlant

@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var magnetCoinComponent: MagnetCoinComponent = %MagnetCoinComponent
@onready var fireComponent: FireComponent = %FireComponent

@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if is_node_ready():
            produceComponent.produceInterval = produceInterval

@export_enum("Sun", "BrainSun", "JalaSun", "Coin") var produceType: String = "Sun":
    set(_produceType):
        produceType = _produceType
        if is_node_ready():
            produceComponent.produceType = produceType

var skinName: String = "Default"

var coinNumList: Array[int] = [0, 0, 0]

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    add_to_group("GoldMagnet")
    produceComponent.produceInterval = produceInterval
    if currentCustom.has("Custom0"):
        skinName = "Sycee"

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Sycee"
    else:
        skinName = "Default"

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if magnetCoinComponent.CanCoinDraw():
        state.send_event("ToMagnet")

func MagnetEntered() -> void :
    sprite.SetAnimation("Attack", false, 0.2)

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
        "Attack":
            CreateProjectile()
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
    if !fireComponent.CanFireCheckOnceByName("CoinSilver", instance.collisionFlags):
        return
    var projectile: TowerDefenseProjectile
    var projectileData: TowerDefenseProjectileCreateData
    if coinNumList[2] > 0:
        for i in 5:
            projectileData = TowerDefenseProjectileCreateData.new(&"CoinDiamond")
            projectileData.skinName = skinName
            projectileData.baseDamage = 1000
            projectileData.collisionFlags = 11
            projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
            coinNumList[2] -= 1
            if coinNumList[2] <= 0:
                break
            await get_tree().create_timer(0.1).timeout
    elif coinNumList[1] > 0:
        for i in 5:
            projectileData = TowerDefenseProjectileCreateData.new(&"CoinGold")
            projectileData.skinName = skinName
            projectileData.baseDamage = 500
            projectileData.collisionFlags = 11
            projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
            coinNumList[1] -= 1
            if coinNumList[1] <= 0:
                break
            await get_tree().create_timer(0.1).timeout
    elif coinNumList[0] > 0:
        for i in 5:
            projectileData = TowerDefenseProjectileCreateData.new(&"CoinSilver")
            projectileData.skinName = skinName
            projectileData.baseDamage = 100
            projectileData.collisionFlags = 11
            projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), projectileData, -1, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
            coinNumList[0] -= 1
            if coinNumList[0] <= 0:
                break
            await get_tree().create_timer(0.1).timeout

func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "skinName": skinName, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    skinName = data.get("skinName", "Default")
