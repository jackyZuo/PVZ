class_name TowerDefenseCharacterEventMathine

static func EventGet(eventName: String) -> TowerDefenseCharacterEventBase:
    match eventName:

        "CreateAddPacket":
            return TowerDefenseCharacterEventCreateAddPacket.new()

        "LuckyBagCreate":
            return TowerDefenseCharacterEventLuckyBagCreate.new()
        "SnowBallSpawn":
            return TowerDefenseCharacterEventSnowBallSpawn.new()
        "YBCreate":
            return TowerDefenseCharacterEventYBCreate.new()
        "SunCreate":
            return TowerDefenseCharacterEventSunCreate.new()
        "CoinCreate":
            return TowerDefenseCharacterEventCoinCreate.new()
        "CreateProjectile":
            return TowerDefenseCharacterEventCreateProjectile.new()
        "CraterCreate":
            return TowerDefenseCharacterEventCraterCreate.new()
        "Forzen":
            return TowerDefenseCharacterEventForzen.new()
        "Hypnoses":
            return TowerDefenseCharacterEventHypnoses.new()
        "IceSpeedDown":
            return TowerDefenseCharacterEventIceSpeedDown.new()
        "Destroy":
            return TowerDefenseCharacterEventDestroy.new()
        "Purify":
            return TowerDefenseCharacterEventPurify.new()
        "WakeUp":
            return TowerDefenseCharacterEventWeakUp.new()
        "PacketSpawn":
            return TowerDefenseCharacterEventPacketSpawn.new()

    return null
