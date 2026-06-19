class_name TowerDefenseConveyorEventAddPacket extends TowerDefenseConveyorEventBase

@export var packet: TowerDefenseConveyorPacketConfig

func Init(data: Dictionary) -> void :
    super.Init(data)
    packet = TowerDefenseConveyorPacketConfig.new()
    packet.Init(data)

func Execute() -> void :
    var conveyorFeature: TowerDefenseBattleFeatureConveyorBelt = TowerDefenseManager.GetConveyorBeltFeature()
    if is_instance_valid(conveyorFeature):
        conveyorFeature.packetList.append(packet)

func Export() -> Dictionary:
    return {
        "EventName": "AddPacket", 
        "Value": packet.Export(), 
    }
