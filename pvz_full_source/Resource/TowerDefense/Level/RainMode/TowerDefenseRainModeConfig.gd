class_name TowerDefenseRainModeConfig extends Resource

@export var type: String = "Default"
@export var aliveTime: float = 30.0
@export var interval: float = 3.0
@export var packetList: Array = []

func Init(data: Dictionary) -> void :
    packetList.clear()
    type = data.get("Type", "Default")
    aliveTime = data.get("AliveTime", 15.0)
    interval = data.get("Interval", 3.0)

    var packetListGet: Array = data.get("Packet", [])
    for packetData: Dictionary in packetListGet:
        var packet: TowerDefenseRainModePacketConfig = TowerDefenseRainModePacketConfig.new()
        packet.Init(packetData)
        packetList.append(packet)

func Export() -> Dictionary:
    var data: Dictionary = {
        "Type" = type, 
        "AliveTime" = aliveTime, 
        "Interval" = interval, 
        "Packet" = [], 
    }
    for packetConfig: TowerDefenseRainModePacketConfig in packetList:
        data["Packet"].append(packetConfig.Export())
    return data
