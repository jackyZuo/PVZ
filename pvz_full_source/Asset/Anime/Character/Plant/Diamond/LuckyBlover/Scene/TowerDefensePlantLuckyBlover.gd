@tool
extends TowerDefensePlant

func Explode() -> void :
    AudioManager.AudioPlay("Diamond", AudioManagerEnum.TYPE.SFX)
    if instance.hypnoses:
        return
    match TowerDefenseManager.currentLevelConfig.packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE, TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
            var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData("GeneralPlant")
            var packetList: Array = packetBankData.GetPlantList()
            var seedBankList = TowerDefenseManager.GetSeedBankList()
            for packetShow: TowerDefenseInGamePacketShow in seedBankList:
                if packetShow.config.saveKey == packet.saveKey:
                    continue
                var packetRandom: String = packetList.pick_random()
                var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
                var override: TowerDefensePacketOverride = TowerDefensePacketOverride.new()
                if packetConfig.GetType() != TowerDefenseEnum.PACKET_TYPE.DIAMOND:
                    override.cost = max(packetConfig.characterConfig.cost - 50, 0)
                packetShow.Cover(packetConfig, override, false, false)
                packetShow.coldDownTimer = packetConfig.GetStartingCooldown()
            var seedbankPacketMax = 16 if TowerDefenseManager.currentLevelConfig.packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET else TowerDefenseManager.seedbankPacketMax
            if seedBankList.size() < seedbankPacketMax:
                for i in seedbankPacketMax - seedBankList.size():
                    var packetRandom: String = packetList.pick_random()
                    var override: TowerDefensePacketOverride = TowerDefensePacketOverride.new()
                    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
                    if packetConfig.GetType() != TowerDefenseEnum.PACKET_TYPE.DIAMOND:
                        override.cost = max(packetConfig.characterConfig.cost - 50, 0)
                    TowerDefenseManager.AddPacket(packetRandom, override)
