class_name TowerDefensePacketEventDelete extends TowerDefensePacketEventBase

@warning_ignore("unused_parameter")
func Init(data: Dictionary) -> void :
    pass

@warning_ignore("unused_parameter")
func Execute(packet: TowerDefenseInGamePacketShow) -> void :
    TowerDefenseManager.GetSeedBank().packetList.erase(packet)
    packet.queue_free()

func Export() -> Dictionary:
    return {
        "EventName" = "Delete", 
        "Value" = {}, 
    }
