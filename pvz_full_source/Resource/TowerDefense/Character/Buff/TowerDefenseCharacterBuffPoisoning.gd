class_name TowerDefenseCharacterBuffPoisoning extends TowerDefenseCharacterBuffConfig

const POISONING_COLOR: Color = Color(0.35, 1.0, 0.0, 1.0)

@export var time: float = 15.0

@export_storage var currentTime: float = 0.0

@export_storage var timer: float = 0.0

func _init() -> void :
    key = "Poisoning"

func Enter() -> void :
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.POISONING:
        character.buff.BuffDelete("Poisoning")
        return

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    if character.instance.die:
        return true
    if timer < 1.5:
        timer += delta
    else:
        timer = 0.0
        character.instance.DealHurt(20, true)
        if is_instance_valid(character.showHealthComponent):
            character.showHealthComponent.MarkDirty()
    character.sprite.meshColor *= POISONING_COLOR
    currentTime += delta
    return currentTime >= time

func Exit() -> void :
    pass

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time + randf_range(-0.2, 0.2))
    currentTime = 0.0
