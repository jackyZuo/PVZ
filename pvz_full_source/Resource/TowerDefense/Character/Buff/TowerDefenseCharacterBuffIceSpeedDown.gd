class_name TowerDefenseCharacterBuffIceSpeedDown extends TowerDefenseCharacterBuffConfig

const ICE_SPEED_DOWN_COLOR: Color = Color(0.2, 0.35, 1.0, 1.0)

@export var time: float = 15.0

@export_storage var currentTime: float = 0.0

func _init() -> void :
    key = "IceSpeedDown"

func Enter() -> void :
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ICESPEEDDOWN:
        character.buff.BuffDelete("IceSpeedDown")
        return
    character.iceSpeedDown = true

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    if character.buff.BuffHas("Frozen"):
        return true
    currentTime += delta
    character.timeScale *= 0.5
    character.sprite.meshColor *= ICE_SPEED_DOWN_COLOR
    return currentTime >= time

func Exit() -> void :
    character.iceSpeedDown = false

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time + randf_range(-0.2, 0.2))
    currentTime = 0.0
