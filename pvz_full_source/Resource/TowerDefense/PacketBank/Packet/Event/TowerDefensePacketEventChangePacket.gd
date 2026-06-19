class_name TowerDefensePacketEventChangePacket extends TowerDefensePacketEventBase

@export var levelPacketConfig: TowerDefenseLevelPacketConfig

var packetConfig: TowerDefensePacketConfig

@warning_ignore("unused_parameter")
func Init(data: Dictionary) -> void :
    levelPacketConfig = TowerDefenseLevelPacketConfig.new()
    levelPacketConfig.Init(data)

@warning_ignore("unused_parameter")
func Execute(packet: TowerDefenseInGamePacketShow) -> void :
    if !is_instance_valid(packetConfig):
        if is_instance_valid(levelPacketConfig):
            packetConfig = levelPacketConfig.GetPacket()
    if is_instance_valid(packetConfig):
        packet.Init(packetConfig)

func Export() -> Dictionary:
    return {
        "EventName" = "ChangePacket", 
        "Value" = levelPacketConfig.Export() if is_instance_valid(levelPacketConfig) else {}, 
    }
