@tool
extends TowerDefensePlantBowlingBase

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if config.customData:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue("PlantJalaNut")
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            currentCustom = [packetValue["Key"]["Custom"]]

@warning_ignore("unused_parameter")
func Bowling(character: TowerDefenseCharacter) -> void :

    Explode()
    Destroy()

func Explode() -> void :
    CreateJalapenoFire(camp, gridPos, 1800.0)
