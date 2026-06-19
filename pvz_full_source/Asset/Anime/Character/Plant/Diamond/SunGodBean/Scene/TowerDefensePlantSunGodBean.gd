@tool
extends TowerDefensePlant

func Explode() -> void :
    for character: TowerDefenseCharacter in TowerDefenseManager.GetCampFriendly(camp):
        character.WeakUp()
        var getProductCommponent: ProduceComponent = character.componentManager.GetComponentFromType("ProduceComponent")
        if is_instance_valid(getProductCommponent):
            getProductCommponent.ImmediateProduct()
    if instance.hypnoses:
        return
    for packetShow: TowerDefenseInGamePacketShow in TowerDefenseManager.GetSeedBankList():
        if packetShow.config.saveKey == packet.saveKey:
            continue
        var packetOverride: TowerDefensePacketOverride = TowerDefensePacketOverride.new()
        if is_instance_valid(packetShow.config.override):
            packetOverride = packetShow.config.override.duplicate(true)
        var charcaterOverride: TowerDefenseCharacterOverride = TowerDefenseCharacterOverride.new()
        var sunCreateEvent: TowerDefenseCharacterEventSunCreate = TowerDefenseCharacterEventSunCreate.new()
        var weakUpEvent: TowerDefenseCharacterEventWeakUp = TowerDefenseCharacterEventWeakUp.new()
        sunCreateEvent.num = 50
        charcaterOverride.spawnEvent.append(sunCreateEvent)
        charcaterOverride.spawnEvent.append(weakUpEvent)
        packetOverride.type = TowerDefenseEnum.PACKET_TYPE.GOLD
        packetOverride.characterOverride = charcaterOverride
        packetShow.Cover(packetShow.config.duplicate(true), packetOverride, false)
