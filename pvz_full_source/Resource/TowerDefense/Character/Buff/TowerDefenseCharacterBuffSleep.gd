class_name TowerDefenseCharacterBuffSleep extends TowerDefenseCharacterBuffConfig

@export var time: float = 15.0

@export_storage var currentTime: float = 0.0

func _init() -> void :
    key = "Sleep"

func Enter() -> void :
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.SLEEP:
        character.buff.BuffDelete("Sleep")
        return
    character.Sleep()

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    character.timeScale *= 0.5
    return currentTime >= time

func Exit() -> void :
    pass

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time + randf_range(-0.2, 0.2))
    currentTime = 0.0
