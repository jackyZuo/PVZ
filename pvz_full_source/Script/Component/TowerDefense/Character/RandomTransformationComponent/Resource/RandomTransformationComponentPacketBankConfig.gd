
class_name RandomTransformationComponentPacketBankConfig extends Resource


@export var packetBankName: String

@export var catagoryUseAll: bool = false

@export var catagoryUseList: Array[String]

@export var rand: float = 1.0



func GetPacketList() -> Array:
    if randf() > rand:
        return []
    var packetList: Array = []
    var packetBank: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData(packetBankName)
    if catagoryUseAll:
        packetList.append_array(packetBank.GetPacketList())
    else:
        for catagory: String in catagoryUseList:
            packetList.append_array(packetBank.GetCategory(catagory))
    return packetList
