@tool
class_name TowerDefenseCrater extends TowerDefenseCharacter

var weatheringComponent: WeatheringComponent
var environmentAnimeComponent: EnvironmentAnimeComponent

var dieDownTimer: float = 0.0
var stage: int = 0
var stageMax: int = 0
var timer: float = 0.0
var isWater: bool = false:
    set(_isWater):
        if isWater != _isWater:
            isWater = _isWater
            sprite.position.y = 0
            timer = 0.0
            SetFrame()

var isNight: bool = false:
    set(_isNight):
        if isNight != _isNight:
            isNight = _isNight
            SetFrame()

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if is_instance_valid(componentManager):
        weatheringComponent = componentManager.GetComponentFromType("WeatheringComponent")
        environmentAnimeComponent = componentManager.GetComponentFromType("EnvironmentAnimeComponent")
    HitBoxDestroy()
    add_to_group("Crater", true)
    stageMax = config.dieDownFliters.size()
    SetFliter(stage)
    if is_instance_valid(cell):
        isWater = cell.gridType.has(TowerDefenseEnum.PLANTGRIDTYPE.WATER)

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    isNight = TowerDefenseManager.GetMapIsNight()

    if isWater:
        timer = environmentAnimeComponent.WaterBob(timer, timeScale)

    weatheringComponent.Processing(delta)

func SetFliter(_stage: int) -> void :
    sprite.SetFliters(config.dieDownFliters, false)
    sprite.SetFliter(config.dieDownFliters[_stage], true)

func SetFrame() -> void :
    environmentAnimeComponent.SetFrame(isNight, isWater)

@warning_ignore("unused_parameter")
func BlowBack(num: float, time: float = 1.0) -> void :
    pass

func DieDown() -> void :
    Destroy()
