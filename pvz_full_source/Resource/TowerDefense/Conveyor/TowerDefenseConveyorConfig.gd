class_name TowerDefenseConveyorConfig extends Resource

@export var type: String = "Default"
@export var interval: float = 3.0
@export var intervalIncreaseEvery: int = 1000000
@export var intervalMagnification: float = 0.5
@export var packetPrioritySpawnList: Array[TowerDefenseLevelPacketConfig] = []
@export var packetList: Array[TowerDefenseConveyorPacketConfig] = []
@export var waveEvent: Array = [[], [], [], [], [], [], [], [], [], [], []]

func Init(waveData: Dictionary) -> void :
    packetList.clear()
    packetPrioritySpawnList.clear()
    type = waveData.get("Type", "Default")
    interval = waveData.get("Interval", 3.0)
    intervalIncreaseEvery = waveData.get("IntervalIncreaseEvery", 2.0)
    intervalMagnification = waveData.get("IntervalMagnification", 0.5)

    var packetPrioritySpawnListGet = waveData.get("PacketPrioritySpawnList", [])
    for packetData in packetPrioritySpawnListGet:
        var packet: TowerDefenseLevelPacketConfig = TowerDefenseLevelPacketConfig.new()
        packet.Init(packetData)
        packetPrioritySpawnList.append(packet)

    var packetListGet: Array = waveData.get("Packet", [])
    for packetData: Dictionary in packetListGet:
        var packet: TowerDefenseConveyorPacketConfig = TowerDefenseConveyorPacketConfig.new()
        packet.Init(packetData)
        packetList.append(packet)

    waveEvent.clear()
    var waveEventGet: Array = waveData.get("WaveEvent", [])
    for eventListData: Array in waveEventGet:
        var eventList: Array[TowerDefenseConveyorEventBase] = []
        for eventData: Dictionary in eventListData:
            var event: TowerDefenseConveyorEventBase = TowerDefenseConveyorEventEnum.EventGet(eventData.get("EventName", ""))
            if is_instance_valid(event):
                event.Init(eventData.get("Value", {}))
                eventList.append(event)
        waveEvent.append(eventList)

func Export() -> Dictionary:
    var data: Dictionary = {
        "Type" = type, 
        "Interval" = interval, 
        "IntervalIncreaseEvery" = intervalIncreaseEvery, 
        "IntervalMagnification" = intervalMagnification, 
        "PacketPrioritySpawnList" = [], 
        "Packet" = [], 
        "WaveEvent" = [], 
    }
    for packetConfig: TowerDefenseLevelPacketConfig in packetPrioritySpawnList:
        data["PacketPrioritySpawnList"].append(packetConfig.Export())
    for packetConfig: TowerDefenseConveyorPacketConfig in packetList:
        data["Packet"].append(packetConfig.Export())
    for waveEventList: Array in waveEvent:
        var eventList = []
        for event: TowerDefenseConveyorEventBase in waveEventList:
            eventList.append(event.Export())
        data["WaveEvent"].append(eventList)
    return data
