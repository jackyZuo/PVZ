@tool
class_name TowerDefenseLevelSurvivalRunner extends Resource

@export var config: TowerDefenseLevelSurvivalConfig
@export var point: int = 0
@export var zombiePool: Array = []
@export var addZombiePoolReachId: int = 0
@export var roundNum = 0
@export var currentZombiePool: Array = []

func Init(_config: TowerDefenseLevelSurvivalConfig) -> void :
    config = _config.duplicate_deep()
    point = config.pointBegin
    zombiePool = config.zombiePoolBase.duplicate_deep()
    if point > config.pointMax:
        point = config.pointMax
    RefreshCurrentZombiePool()

@warning_ignore("unused_parameter")
func WaveReach(waveId: int, isBigWave: bool) -> void :
    if !isBigWave:
        point += config.pointIncrementPerWave
    else:
        point += config.pointIncrementPerBigWave
    if point > config.pointMax:
        point = config.pointMax

func RoundReach(_roundNum: int) -> void :
    roundNum = _roundNum
    if config.roundDayNightChange:
        TowerDefenseManager.MapDayNightSwitch(5.0, -1)
    point += config.pointIncrementPerRound
    if point > config.pointMax:
        point = config.pointMax
    var checkId: int = addZombiePoolReachId
    for id in range(checkId, config.zombiePoolRoundAdd.size(), 1):
        var roundAddConfig: TowerDefenseLevelSurvivalZombiePoolRoundAddConfig = config.zombiePoolRoundAdd[id]
        if roundAddConfig._round <= roundNum:
            zombiePool.append_array(roundAddConfig.zombieList)
            addZombiePoolReachId = id
            continue
        break
    RefreshCurrentZombiePool()

func RefreshCurrentZombiePool() -> Array:
    currentZombiePool.clear()
    var zombiePoolTemp = zombiePool.duplicate()
    for i in randi_range(7, 9):
        var pick = zombiePoolTemp.pick_random()
        currentZombiePool.append(pick)
        if zombiePoolTemp.size() < 0:
            break
    return currentZombiePool
