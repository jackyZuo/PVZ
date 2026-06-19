@tool
class_name TowerDefenseLevelSurvivalConfig extends Resource

@export var json: JSON:
    set(_json):
        json = _json
        if is_instance_valid(json):
            Init()
            notify_property_list_changed()

@export var roundLimit: int = -1
@export var roundDayNightChange: bool = false
@export var pointIncrementPerWave: int = 50
@export var pointIncrementPerBigWave: int = 100
@export var pointIncrementPerRound: int = 200
@export var pointBegin: int = 100
@export var pointMax: int = 10000000
@export var pointBigWaveScale: float = 1.5
@export var zombiePoolBase: Array = ["ZombieNormal", "ZombieNormalCone"]
@export var zombiePoolRoundAdd: Array[TowerDefenseLevelSurvivalZombiePoolRoundAddConfig]

func Init() -> void :
    var data = json.data
    Load(data)

func Load(data: Dictionary) -> void :
    roundLimit = data.get("RoundLimit", -1)
    roundDayNightChange = data.get("RoundDayNightChange", false)
    pointIncrementPerWave = data.get("PointIncrementPerWave", 50)
    pointIncrementPerBigWave = data.get("PointIncrementPerBigWave", 100)
    pointIncrementPerRound = data.get("PointIncrementPerRound", 200)
    pointBegin = data.get("PointBegin", 100)
    pointMax = data.get("PointMax", 10000000)
    pointBigWaveScale = data.get("PointBigWaveScale", 1.5)

    var zombiePoolSetting: Dictionary = data.get("ZombiePoolSetting", {})
    zombiePoolBase = zombiePoolSetting.get("ZombiePoolBase", [])
    zombiePoolRoundAdd.clear()
    for zombiePoolData: Dictionary in zombiePoolSetting.get("ZombiePoolRoundAdd", []):
        var zombiePoolRoubndAddConfig: TowerDefenseLevelSurvivalZombiePoolRoundAddConfig = TowerDefenseLevelSurvivalZombiePoolRoundAddConfig.new()
        zombiePoolRoubndAddConfig.Init(zombiePoolData)
        zombiePoolRoundAdd.append(zombiePoolRoubndAddConfig)

func Export() -> Dictionary:
    var data: Dictionary = {
        "PointIncrementPerWave": pointIncrementPerWave, 
        "PointIncrementPerBigWave": pointIncrementPerBigWave, 
        "PointIncrementPerRound": pointIncrementPerRound, 
        "PointBegin": pointBegin, 
        "PointMax": pointMax, 
        "PointBigWaveScale": pointBigWaveScale, 
        "ZombiePoolSetting": {
            "ZombiePoolBase": zombiePoolBase, 
            "ZombiePoolRoundAdd": []
        }
    }
    for zombiePoolRoundAddConfig: TowerDefenseLevelSurvivalZombiePoolRoundAddConfig in zombiePoolRoundAdd:
        data["ZombiePoolSetting"]["ZombiePoolRoundAdd"].append(zombiePoolRoundAddConfig.Export())
    return data
