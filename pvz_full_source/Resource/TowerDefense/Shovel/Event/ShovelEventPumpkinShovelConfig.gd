class_name ShovelEventPumpkinShovelConfig extends ShovelEventConfig

func Execute(character: TowerDefenseCharacter) -> void :
    var isSurround: bool = false
    var hasSurround: bool = false
    var surround: TowerDefenseCharacter = null
    if is_instance_valid(character.cell):
        surround = character.cell.GetSurround()
        if is_instance_valid(surround):
            hasSurround = true
            if surround == character:
                isSurround = true
    if !isSurround:
        if hasSurround:
            surround.Health(character.instance.hitpoints)
        else:
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPumpkin")
            var pumpkin: TowerDefenseCharacter = packetConfig.Plant(character.gridPos)
            if is_instance_valid(pumpkin):
                if pumpkin.instance.hitpoints - character.instance.hitpoints > 0:
                    pumpkin.Hurt(pumpkin.instance.hitpoints - character.instance.hitpoints)
                else:
                    pumpkin.Health(character.instance.hitpoints - pumpkin.instance.hitpoints)
    else:
        if surround.config.name == "PlantPumpkin":
            surround.Recycle(min(1, 0.5 * (surround.instance.hitpoints / surround.config.hitpoints)))
