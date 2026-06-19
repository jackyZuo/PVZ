@tool
extends TowerDefensePlant

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if config.customData:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue("PlantWallnutABC_A")
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            currentCustom = [packetValue["Key"]["Custom"]]

func DestroySet() -> void :
    super.DestroySet()
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
    await get_tree().physics_frame
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantWallnutABC_C")
    var plant: TowerDefenseCharacter = packetConfig.Plant(gridPos)
    if is_instance_valid(plant):
        if instance.hypnoses:
            plant.Hypnoses()
