class_name TowerDefenseCharacterBuffFluorescence extends TowerDefenseCharacterBuffConfig

const FLUORESCENCE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)

const LIGHT_AREA = preload("uid://byee3s263f1rj")
const FLUORESCENCE_FOG = preload("uid://bmmugje73kf7e")

@export var time: float = 50.0

@export_storage var currentTime: float = 0.0

var fog: Node
var light: Node

func _init() -> void :
    key = "Fluorescence"

func Enter() -> void :
    fog = FLUORESCENCE_FOG.instantiate()
    character.spriteGroup.add_child(fog)

    light = LIGHT_AREA.instantiate()
    character.spriteGroup.add_child(light)

    character.instance.canBeCollection = false
    character.instance.physiqueTypeFlags |= TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LIGHT

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    character.sprite.meshColor *= FLUORESCENCE_COLOR
    currentTime += delta
    return currentTime >= time

func Exit() -> void :
    if is_instance_valid(fog):
        fog.queue_free()
    if is_instance_valid(light):
        light.queue_free()
    character.instance.canBeCollection = true
    character.instance.physiqueTypeFlags &= ~ TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LIGHT

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time + randf_range(-0.2, 0.2))
    currentTime = 0.0
