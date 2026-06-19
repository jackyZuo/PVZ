class_name TowerDefenseBattleFeatureSun extends TowerDefenseBattleFeature

signal sunCollect(num: int)
signal sunChange(num: int)

var config: TowerDefenseLevelSunManagerConfig
var type: String = "Normal"
var spawnInterval: float = 25.0
var spawnNum: int = 25
var movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.LAND
var isRunning: bool = false
var timer: float = 0.0

var sunNum: int = 50



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelSunManagerConfig.new()
    config.Init(data)
    sunNum = config.begin

func GameInit() -> void :
    SetSun(config.begin)

func GameStart() -> void :
    var process = GetProcess()
    if process is TowerDefenseBattleProcessWave and process.isSurvival and is_instance_valid(process.survivalRunner) and process.survivalRunner.roundNum > 0:
        type = config.type
        spawnInterval = config.spawnInterval
        spawnNum = config.spawnNum
        movingMethod = config.movingMethod
        timer = spawnInterval - 6.0
    else:
        SunInit(config)
    isRunning = true

func GameStartFromProgress() -> void :
    isRunning = true

func GameFail() -> void :
    isRunning = false

func Process(delta: float) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if isRunning && config.open && ( !mapFeature.config.isNight || mapFeature.config.useSunFall):
        if timer < spawnInterval:
            timer += delta
        else:
            SunCreate()
            timer = 0.0

func SyncSerialize() -> Dictionary:
    return {}

func SyncDeserialize(_data: Dictionary) -> void :
    pass

func SaveFeature() -> Dictionary:
    return {
        "timer": timer, 
        "isRunning": isRunning, 
        "spawnInterval": spawnInterval, 
        "spawnNum": spawnNum, 
        "type": type, 
        "movingMethod": movingMethod, 
        "sunNum": sunNum, 
    }

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
    isRunning = _data.get("isRunning", false)
    spawnInterval = _data.get("spawnInterval", spawnInterval)
    spawnNum = _data.get("spawnNum", spawnNum)
    type = _data.get("type", type)
    movingMethod = _data.get("movingMethod", movingMethod)
    sunNum = _data.get("sunNum", sunNum)



func AddSun(num: int) -> void :
    sunNum += num
    sunCollect.emit(num)
    sunChange.emit(sunNum)

func UseSun(num: int) -> void :
    sunNum -= num
    sunChange.emit(sunNum)

func SetSun(num: int) -> void :
    sunNum = num
    sunChange.emit(sunNum)

func SunInit(_config: TowerDefenseLevelSunManagerConfig) -> void :
    SetSun(_config.begin)
    type = _config.type
    spawnInterval = _config.spawnInterval
    spawnNum = _config.spawnNum
    movingMethod = _config.movingMethod
    timer = spawnInterval - 6.0

func SunCreate() -> Node2D:
    var posX: float = randf_range(TowerDefenseManager.GetMapGridBeginPos().x, TowerDefenseManager.GetMapGroundRight())
    var height: float = randf_range(TowerDefenseManager.GetMapGridBeginPos().y + 200, TowerDefenseManager.GetMapGroundDown() - TowerDefenseManager.GetMapGridBeginPos().y)
    var sun
    match type:
        "Normal":
            sun = TowerDefenseManager.SunCreate(Vector2(posX, TowerDefenseManager.GetMapGridBeginPos().y - 100), spawnNum, movingMethod, height, Vector2(0, 100.0))
        "Brain":
            sun = TowerDefenseManager.BrainSunCreate(Vector2(posX, TowerDefenseManager.GetMapGridBeginPos().y - 100), spawnNum, movingMethod, height, Vector2(0, 100.0))
        "Jala":
            sun = TowerDefenseManager.JalapenoSunCreate(Vector2(posX, TowerDefenseManager.GetMapGridBeginPos().y - 100), spawnNum, movingMethod, height, Vector2(0, 100.0))
    return sun
