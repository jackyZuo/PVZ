class_name TowerDefenseLevelPacketBankConfig extends Resource

@export var packetBankType: String = "GeneralPlant"

func Init(data: Dictionary) -> void :
    packetBankType = data.get("PacketBankName")
