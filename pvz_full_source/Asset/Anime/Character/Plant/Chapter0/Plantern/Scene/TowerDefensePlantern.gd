@tool
extends TowerDefensePlant

@onready var light: PointLight2D = %Light

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    AudioManager.AudioPlay("Plantern", AudioManagerEnum.TYPE.SFX)

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")
