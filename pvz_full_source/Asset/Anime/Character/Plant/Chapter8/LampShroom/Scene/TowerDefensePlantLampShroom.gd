@tool
extends TowerDefensePlant

var spawnPacketList: Array[Array] = [
    ["PlantSunFlagbean", "PlantIceSunShroom"], 
    ["PlantJalaTorch", "PlantCherryPea"], 
    ["PlantHypnoBean", "ZombieNormalDoomShroomBlackHelmet"], 
    ["PlantKabbageTail", "PlantTabooBean"], 
    ["PlantGarlicChomper", "PlantGarlicChomper"]
]

func Explode() -> void :
    AudioManager.AudioPlay("Diamond", AudioManagerEnum.TYPE.SFX)
    var packetNames = spawnPacketList.pick_random()
    var packetConfig1: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetNames[0])
    if instance.hypnoses:
        packetConfig1.overrideHypnoses = true
    SpawnPacket(packetConfig1, global_position - Vector2(30, 0), 15.0, false, false, true)
    var packetConfig2: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetNames[1])
    if instance.hypnoses:
        packetConfig2.overrideHypnoses = true
    SpawnPacket(packetConfig2, global_position + Vector2(10, 0), 15.0, false, false, true)
