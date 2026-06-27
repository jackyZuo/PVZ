@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(cell):
        var characterList: Array[TowerDefenseCharacter] = cell.GetCharacterList()
        characterList = characterList.filter( func(character: TowerDefenseCharacter):
            return character is TowerDefensePlant && character.config.name != config.name && character.camp == camp
        )
        for character in characterList:
            if is_instance_valid(character):
                character.WakeUp()
                if character.cost > 0 && !instance.hypnoses:
                    var coinGoldCount = floor(character.cost / 50)
                    for i in coinGoldCount:
                        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                        item.gridPos = gridPos
                    for i in floor((character.cost - coinGoldCount * 50) / 10):
                        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                        item.gridPos = gridPos
        if characterList.size() > 0 && randf() < 0.05:
            for character in characterList:
                if is_instance_valid(character):
                    character.Destroy(false)
            var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData("GeneralPlant")
            var packetList: Array = packetBankData.GetCategory("Gold")
            var packetRandom: String = packetList.pick_random()
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
            while !cell.CanPacketPlant(packetConfig) && packetList.size() > 1:
                packetList.erase(packetRandom)
                packetRandom = packetList.pick_random()
                packetConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
            if packetList.size() > 1:
                var plant = packetConfig.Plant(gridPos, true)
                plant.WakeUp()
                if instance.hypnoses:
                    plant.Hypnoses()
                for character in characterList:
                    character.queue_free()
            else:
                for character in characterList:
                    if is_instance_valid(character):
                        cell.CharacterPlant(character.packet, character)
