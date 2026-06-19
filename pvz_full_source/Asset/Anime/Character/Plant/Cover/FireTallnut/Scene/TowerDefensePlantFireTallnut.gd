@tool
extends TowerDefensePlant
const FIRE_TALLNUT_SKIN_1_1 = preload("uid://daqku0t4djmni")
const FIRE_TALLNUT_SKIN_1_2 = preload("uid://ckcn353sc7ri8")
const FIRE_TALLNUT_SKIN_1_3 = preload("uid://beejwpcgngjgm")
const FIRE_TALLNUT_SKIN_2_1 = preload("uid://cum4455awia7e")
const FIRE_TALLNUT_SKIN_2_2 = preload("uid://dodeke0xu60l4")
const FIRE_TALLNUT_SKIN_2_3 = preload("uid://bbjp2p5tb73oi")

@onready var attackShape: CollisionShape2D = %AttackShape
@onready var light: PointLight2D = %Light

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("FireTallnut_skin1_1.png", FIRE_TALLNUT_SKIN_1_1)
                sprite.SetReplace("FireTallnut_skin2_1.png", FIRE_TALLNUT_SKIN_2_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("FireTallnut_skin1_1.png", FIRE_TALLNUT_SKIN_1_2)
                sprite.SetReplace("FireTallnut_skin2_1.png", FIRE_TALLNUT_SKIN_2_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("FireTallnut_skin1_1.png", FIRE_TALLNUT_SKIN_1_3)
                sprite.SetReplace("FireTallnut_skin2_1.png", FIRE_TALLNUT_SKIN_2_3)
