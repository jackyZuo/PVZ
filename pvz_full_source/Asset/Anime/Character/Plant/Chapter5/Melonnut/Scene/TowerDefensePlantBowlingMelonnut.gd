@tool
extends TowerDefensePlantBowlingBase

@onready var fireComponent: FireComponent = %FireComponent

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if config.customData:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue("PlantMelonnut")
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            currentCustom = [packetValue["Key"]["Custom"]]
