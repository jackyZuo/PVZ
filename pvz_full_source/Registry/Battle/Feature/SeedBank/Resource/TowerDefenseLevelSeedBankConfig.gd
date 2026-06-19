class_name TowerDefenseLevelSeedBankConfig extends Resource

@export var plantColumn: bool = false
@export var packetColdDownStart: bool = true
@export var packetColdDownUse: bool = true
@export var method: TowerDefenseEnum.LEVEL_SEEDBANK_METHOD = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE
@export var packetList: Array[TowerDefenseLevelPacketConfig]

func Init(data: Dictionary) -> void :
    method = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.get(data.get("Method", "NOONE").to_upper())
    plantColumn = data.get("PlantColumn", false)
    packetColdDownStart = data.get("ColdDownStart", true)
    packetColdDownUse = data.get("ColdDownUse", true)
    var packetBankValue = data.get("Packet", [])
    for packetData in packetBankValue:
        var packet: TowerDefenseLevelPacketConfig = TowerDefenseLevelPacketConfig.new()
        packet.Init(packetData)
        packetList.append(packet)
