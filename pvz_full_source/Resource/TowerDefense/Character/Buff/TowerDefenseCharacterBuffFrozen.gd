class_name TowerDefenseCharacterBuffFrozen extends TowerDefenseCharacterBuffConfig

const ICE_SPEED_DOWN_COLOR: Color = Color(0.2, 0.35, 1.0, 1.0)

@export var time: float = 8.0
@export var iceSpeedDownTime: float = 15.0
@export_storage var currentTime: float = 0.0

func _init() -> void :
    key = "Frozen"

func Enter() -> void :
    if character.instance.maskFlags == 0 || character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
        character.buff.BuffDelete("Frozen")
        return
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.FROZEN:
        character.buff.BuffDelete("Frozen")
        return
    character.buff.BuffDelete("Burn")
    character.icetrapSprite.visible = true

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    character.sprite.meshColor *= ICE_SPEED_DOWN_COLOR
    character.timeScale *= 0.0
    return character.nearDie || character.die || currentTime >= time

func Exit() -> void :
    character.icetrapSprite.visible = false
    character.CreateIceTrap()
    if iceSpeedDownTime == 0.0:
        pass
    else:
        var iceSpeedDownBuff: TowerDefenseCharacterBuffIceSpeedDown = TowerDefenseCharacterBuffIceSpeedDown.new()
        iceSpeedDownBuff.time = iceSpeedDownTime
        character.buff.BuffAdd(iceSpeedDownBuff)

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time + randf_range(-0.2, 0.2))
    iceSpeedDownTime = config.iceSpeedDownTime
    currentTime = 0.0
