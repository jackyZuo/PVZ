@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(cell):
        var upCost = (25 if randf() > 0.5 else 50)
        var packetList
        var characterList: Array[TowerDefenseCharacter] = cell.GetCharacterList()
        characterList = characterList.filter( func(character: TowerDefenseCharacter):
            return character is TowerDefensePlant && character.config.name != config.name && character.camp == camp
        )
        characterList.sort_custom( func(a: TowerDefenseCharacter, b: TowerDefenseCharacter) -> bool:
            var a_on_pot: bool = is_instance_valid(cell.characterSlotDictionary.get(a)) and cell.characterSlotDictionary[a].config.plantGridOverrideType in [TowerDefenseEnum.PLANTGRIDTYPE.POT, TowerDefenseEnum.PLANTGRIDTYPE.LILYPAD]
            var b_on_pot: bool = is_instance_valid(cell.characterSlotDictionary.get(b)) and cell.characterSlotDictionary[b].config.plantGridOverrideType in [TowerDefenseEnum.PLANTGRIDTYPE.POT, TowerDefenseEnum.PLANTGRIDTYPE.LILYPAD]
            return a_on_pot and not b_on_pot
        )
        if characterList.is_empty():
            packetList = TowerDefenseManager.GetPacketConfigCostLowerWithTypeList(upCost, [TowerDefenseEnum.PACKET_TYPE.WHITE, TowerDefenseEnum.PACKET_TYPE.GOLD, TowerDefenseEnum.PACKET_TYPE.DIAMOND, TowerDefenseEnum.PACKET_TYPE.COLOUR, TowerDefenseEnum.PACKET_TYPE.DIAMOND, TowerDefenseEnum.PACKET_TYPE.STAR, TowerDefenseEnum.PACKET_TYPE.ORIGINAL])
            if packetList.size() > 0:
                var packetConfig: TowerDefensePacketConfig = packetList.pick_random()
                if instance.hypnoses:
                    packetConfig.overrideHypnoses = true
                SpawnPacket(packetConfig, global_position, 15.0, false)
            return

        for character in characterList:
            if is_instance_valid(character):
                character.WakeUp()
                var _cost = character.cost + upCost
                packetList = TowerDefenseManager.GetPacketConfigCostLowerWithTypeList(_cost, [TowerDefenseEnum.PACKET_TYPE.WHITE, TowerDefenseEnum.PACKET_TYPE.GOLD, TowerDefenseEnum.PACKET_TYPE.DIAMOND, TowerDefenseEnum.PACKET_TYPE.COLOUR, TowerDefenseEnum.PACKET_TYPE.DIAMOND, TowerDefenseEnum.PACKET_TYPE.STAR, TowerDefenseEnum.PACKET_TYPE.ORIGINAL]).filter( func(_packet):
                    return _packet.characterConfig.cost > character.cost
                )
                if packetList.size() > 0:
                    character.Destroy()
                    var packetConfig: TowerDefensePacketConfig = packetList.pick_random()
                    if instance.hypnoses:
                        packetConfig.overrideHypnoses = true
                    SpawnPacket(packetConfig, global_position, 15.0, false)
                else:
                    if instance.hypnoses:
                        BrainSunCreate(global_position, upCost)
                    else:
                        SunCreate(global_position, upCost)
