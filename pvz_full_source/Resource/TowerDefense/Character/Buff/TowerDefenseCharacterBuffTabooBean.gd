class_name TowerDefenseCharacterBuffTabooBean extends TowerDefenseCharacterBuffConfig

const TABOO_BEAN_COLOR: Color = Color(0.359, 0.359, 0.359, 1.0)

@export var time: float = 35.0

@export_storage var currentTime: float = 0.0

@export_storage var blink: bool = false

func _init() -> void :
    key = "TabooBean"

func Enter() -> void :
    character.timeScaleInit = 5.0

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    character.sprite.meshColor *= TABOO_BEAN_COLOR
    if !blink:
        if currentTime >= time - 5:
            character.SetSpriteGroupShaderParameter("blink", true)
            blink = true
    return currentTime >= time

func Exit() -> void :
    character.Destroy()
    character.CraterCreate(true)

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    pass
