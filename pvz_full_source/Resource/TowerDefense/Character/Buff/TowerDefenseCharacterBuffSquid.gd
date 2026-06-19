class_name TowerDefenseCharacterBuffSquid extends TowerDefenseCharacterBuffConfig

const SQUID_COLOR: Color = Color(0.184, 0.184, 0.184, 1.0)

@export var time: float = 15.0

@export_storage var currentTime: float = 0.0

func _init() -> void :
    key = "Squid"

func Enter() -> void :
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.SQUID:
        character.buff.BuffDelete("Squid")
        return
    character.buff.BuffAdd(TowerDefenseCharacterBuffNormalHit.new())

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    character.buff.BuffAdd(TowerDefenseCharacterBuffNormalHit.new())
    character.sprite.meshColor = SQUID_COLOR
    character.timeScale = min(character.timeScale, 0.5)
    currentTime += delta
    return currentTime >= time

func Exit() -> void :
    pass

func SetAttackNum(num: float) -> float:
    return num * 2.0

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time + randf_range(-0.2, 0.2))
    currentTime = 0.0
