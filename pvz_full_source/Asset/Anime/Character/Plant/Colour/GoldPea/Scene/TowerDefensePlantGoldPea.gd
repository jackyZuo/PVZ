@tool
extends TowerDefensePlant

@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var magnetCoinComponent: MagnetCoinComponent = %MagnetCoinComponent
@onready var fireComponent: FireComponent = %FireComponent

var coinNumList: Array[int] = [0, 0, 0]

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

@export var fireInterval: float = 1.5:
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

@export var projectileName: String = "GoldPea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    produceComponent.produceInterval = produceInterval
    fireComponent.fireInterval = fireInterval

func IdleEntered() -> void :
    super.IdleEntered()
    fireComponent.alive = true
    add_to_group("GoldMagnet")

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if magnetCoinComponent.CanCoinDraw():
        state.send_event("ToMagnet")

func IdleExited() -> void :
    super.IdleExited()

func MagnetEntered() -> void :
    fireComponent.alive = false
    sprite.SetAnimation("Attract", false, 0.2)

@warning_ignore("unused_parameter")
func MagnetProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func MagnetExited() -> void :
    fireComponent.alive = true

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "action":
            magnetCoinComponent.CoinDraw()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Attract":
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
    var projectile: TowerDefenseProjectile
    if coinNumList[2] > 0:
        for i in coinNumList[2]:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinDiamond")
            _projectileData.baseDamage = 1000
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), _projectileData, instance.collisionFlags | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
    if coinNumList[1] > 0:
        for i in coinNumList[1]:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinGold")
            _projectileData.baseDamage = 500
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), _projectileData, instance.collisionFlags | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
    if coinNumList[0] > 0:
        for i in coinNumList[0]:
            var _projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinSilver")
            _projectileData.baseDamage = 100
            _projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
            projectile = fireComponent.CreateProjectileByData(0, Vector2(300, 0), _projectileData, instance.collisionFlags | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE, camp, Vector2.ZERO)
            projectile.projectileBodyNode.scale.x = scale.x
            projectile.gridPos = gridPos
    coinNumList = [0, 0, 0]
    await get_tree().create_timer(0.1).timeout

func ExportVariantSave() -> Dictionary:
    return {"produceInterval": produceInterval, 
        "fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "GoldPea")
    fireInterval = data.get("fireInterval", 1.5)
