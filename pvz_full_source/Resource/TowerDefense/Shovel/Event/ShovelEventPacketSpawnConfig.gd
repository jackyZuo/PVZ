class_name ShovelEventPacketSpawnConfig extends ShovelEventConfig

@export var packetName: String = ""
@export var everyNum: int = 50

func Execute(character: TowerDefenseCharacter) -> void :
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
    if !is_instance_valid(packetConfig):
        return
    if packetName != "ItemMagnetWave":
        for i in floor(character.cost / everyNum):
            packetConfig.Plant.call_deferred(character.gridPos)
    else:
        if character.cost >= everyNum:
            var itemMagnetWave = packetConfig.Plant(character.gridPos)
            itemMagnetWave.drawNum = floor(character.cost / everyNum)
