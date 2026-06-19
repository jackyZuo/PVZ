@tool
extends TowerDefensePlant

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

func DestroySet() -> void :
    super.DestroySet()
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
    await get_tree().physics_frame
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantWallnutABC_B")
    var plant: TowerDefenseCharacter = packetConfig.Plant(gridPos)
    if is_instance_valid(plant):
        if instance.hypnoses:
            plant.Hypnoses()
