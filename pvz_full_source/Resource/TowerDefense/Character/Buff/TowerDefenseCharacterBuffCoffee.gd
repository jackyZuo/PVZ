class_name TowerDefenseCharacterBuffCoffee extends TowerDefenseCharacterBuffConfig

@export var timeScaleValue: float = 3.0
@export var time: float = 15.0

@export_storage var currentTime: float = 0.0
@export_storage var blink: bool = false

func _init() -> void :
    key = "Coffee"

func Enter() -> void :
    pass

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    character.timeScale *= timeScaleValue
    if !blink:
        if currentTime >= time - 3:
            character.SetSpriteGroupShaderParameter("blink", true)
            blink = true
    return currentTime >= time

func Exit() -> void :
    character.SetSpriteGroupShaderParameter("blink", false)

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    var coffeeConfig: TowerDefenseCharacterBuffCoffee = config as TowerDefenseCharacterBuffCoffee
    if coffeeConfig:
        timeScaleValue = coffeeConfig.timeScaleValue
        time = coffeeConfig.time
        currentTime = 0.0
        blink = false
        character.SetSpriteGroupShaderParameter("blink", false)
