class_name TowerDefensePacketEventChangePacket extends TowerDefensePacketEventBase

@export var levelPacketConfig: TowerDefenseLevelPacketConfig

var packetConfig: TowerDefensePacketConfig


var count: int = 1

@warning_ignore("unused_parameter")
func Init(data: Dictionary) -> void :
    levelPacketConfig = TowerDefenseLevelPacketConfig.new()
    levelPacketConfig.Init(data)
    count = data.get("Count", 1)

@warning_ignore("unused_parameter")
func Execute(packet: TowerDefenseInGamePacketShow) -> void :
    if count > 1:
        count -= 1
        return
    if !is_instance_valid(packetConfig):
        if is_instance_valid(levelPacketConfig):
            packetConfig = levelPacketConfig.GetPacket()
    if is_instance_valid(packetConfig):
        packet.Init(packetConfig)

func Export() -> Dictionary:
    var data: Dictionary = {
        "EventName" = "ChangePacket", 
        "Value" = levelPacketConfig.Export() if is_instance_valid(levelPacketConfig) else {}, 
    }
    if count > 1:
        data["Count"] = count
    return data
