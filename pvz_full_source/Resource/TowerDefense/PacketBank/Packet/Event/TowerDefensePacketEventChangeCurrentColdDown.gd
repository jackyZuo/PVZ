class_name TowerDefensePacketEventChangeCurrentColdDown extends TowerDefensePacketEventBase

@export var value: float = 0.0

@warning_ignore("unused_parameter")
func Init(data: Dictionary) -> void :
    value = data.get("Value", 0.0)

@warning_ignore("unused_parameter")
func Execute(packet: TowerDefenseInGamePacketShow) -> void :
    packet.coldDownOpen = true
    packet.coldDownTimer = value

func Export() -> Dictionary:
    return {
        "EventName" = "ChangeCurrentColdDown", 
        "Value" = {"Value" = value}, 
    }
