@tool
extends TowerDefensePlant

var MINI_NUT_SKIN_1_1 = preload("uid://ddspigw28gho4")
var MINI_NUT_SKIN_1_2 = preload("uid://bdsdvjbrep741")
var MINI_NUT_SKIN_1_3 = preload("uid://bx2nv5g7iu678")

@onready var timerComponent: TimerComponent = %TimerComponent

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if config.customData:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue("PlantNutpult")
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            print(packetValue["Key"]["Custom"])
            currentCustom = [packetValue["Key"]["Custom"]]

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Destroy"):
        timerComponent.Run("Destroy", 30)

@warning_ignore("unused_parameter")
func Timeout(timerName: String) -> void :
    Destroy()

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("MiniNut_skin1_1.png", MINI_NUT_SKIN_1_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("MiniNut_skin1_1.png", MINI_NUT_SKIN_1_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("MiniNut_skin1_1.png", MINI_NUT_SKIN_1_3)
