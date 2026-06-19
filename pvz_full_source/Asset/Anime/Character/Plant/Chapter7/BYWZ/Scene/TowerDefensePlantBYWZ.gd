@tool
extends TowerDefensePlant

func Explode() -> void :
    AudioManager.AudioPlay("Diamond", AudioManagerEnum.TYPE.SFX)
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfigCostLowerWithTypeList(100, [TowerDefenseEnum.PACKET_TYPE.WHITE, TowerDefenseEnum.PACKET_TYPE.ORIGINAL]).pick_random()
    if instance.hypnoses:
        packetConfig.overrideHypnoses = true
    SpawnPacket(packetConfig, global_position, 15.0, false)
