class_name TowerDefenseCharacterBuffHypnoses extends TowerDefenseCharacterBuffConfig

const CHARM_COLOR: Color = Color(0.83, 0.34, 0.81, 1.0)

@export var time: float = -1
@export_storage var currentTime: float = 0.0

@export_storage var saveCamp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.NOONE

func _init() -> void :
    key = "Hypnoses"

func Enter() -> void :
    if canFliter:
        if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES:
            if saveCamp == TowerDefenseEnum.CHARACTER_CAMP.NOONE:
                saveCamp = character.camp
            character.buff.BuffDelete("Hypnoses")
            return
    character.buff.BuffDelete("Butter")
    character.buff.BuffDelete("Dizziness")
    character.buff.BuffDelete("Frozen")
    character.instance.hypnoses = true
    if saveCamp == TowerDefenseEnum.CHARACTER_CAMP.NOONE:
        saveCamp = character.camp
    if character.camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
        character.camp = TowerDefenseEnum.CHARACTER_CAMP.PLANT
    elif character.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        character.camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
    character.scale.x = -1
    if saveCamp == character.camp:
        character.buff.BuffDelete("Hypnoses")

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    character.sprite.meshColor *= CHARM_COLOR
    return (time != -1 && currentTime >= time)

func Exit() -> void :
    character.instance.hypnoses = false
    character.camp = saveCamp
    character.scale.x = 1

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time)
    if config.time == -1:
        time = -1
    currentTime = 0.0
