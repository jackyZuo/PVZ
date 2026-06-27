@tool
extends TowerDefensePlant

func Explode() -> void :
    for character: TowerDefenseCharacter in TowerDefenseManager.GetCampFriendly(camp):
        character.WakeUp()
        var getProductCommponent: ProduceComponent = character.componentManager.GetComponentFromType("ProduceComponent")
        if is_instance_valid(getProductCommponent):
            getProductCommponent.ImmediateProduct()
    if instance.hypnoses:
        return
    var _packetShowList: Array[TowerDefenseInGamePacketShow] = []
    _packetShowList.append_array(TowerDefenseManager.GetSeedBankList())
    var _conveyorBeltFeature: TowerDefenseBattleFeatureConveyorBelt = TowerDefenseManager.GetConveyorBeltFeature()
    if is_instance_valid(_conveyorBeltFeature):
        for _child in _conveyorBeltFeature.GetPacketChildren():
            if _child is TowerDefenseInGamePacketShow:
                _packetShowList.append(_child)
    for packetShow: TowerDefenseInGamePacketShow in _packetShowList:
        var identifyKey: String = packetShow.originalSaveKey if packetShow.originalSaveKey != "" else packetShow.config.saveKey
        if identifyKey == packet.saveKey:
            continue
        if packetShow.config.saveKey == "PlantCardless":
            continue
        var isGold: bool = is_instance_valid(packetShow.config.override) && packetShow.config.override.type == TowerDefenseEnum.PACKET_TYPE.GOLD
        if isGold:
            var changePacketEvent: TowerDefensePacketEventChangePacket = _GetChangePacketEvent(packetShow)
            if changePacketEvent != null:
                changePacketEvent.count += 1
        else:
            var packetOverride: TowerDefensePacketOverride = TowerDefensePacketOverride.new()
            var charcaterOverride: TowerDefenseCharacterOverride = TowerDefenseCharacterOverride.new()
            var sunCreateEvent: TowerDefenseCharacterEventSunCreate = TowerDefenseCharacterEventSunCreate.new()
            var wakeUpEvent: TowerDefenseCharacterEventWakeUp = TowerDefenseCharacterEventWakeUp.new()
            sunCreateEvent.num = 50
            charcaterOverride.spawnEvent.append(sunCreateEvent)
            charcaterOverride.spawnEvent.append(wakeUpEvent)
            packetOverride.type = TowerDefenseEnum.PACKET_TYPE.GOLD
            packetOverride.characterOverride = charcaterOverride
            packetShow.Cover(packetShow.config.duplicate(true), packetOverride, false)

func _GetChangePacketEvent(packetShow: TowerDefenseInGamePacketShow) -> TowerDefensePacketEventChangePacket:
    if !is_instance_valid(packetShow.config.override):
        return null
    for event: TowerDefensePacketEventBase in packetShow.config.override.eventPlant:
        if event is TowerDefensePacketEventChangePacket:
            return event
    return null
