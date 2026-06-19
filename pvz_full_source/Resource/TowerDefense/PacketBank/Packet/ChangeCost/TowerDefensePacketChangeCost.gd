class_name TowerDefensePacketChangeCost extends Resource

@export_enum("Increase", "Decrease", "Set") var method: String = "Increase"
@export var amontDictionary: Dictionary[TowerDefenseEnum.PACKET_TYPE, int] = {
    TowerDefenseEnum.PACKET_TYPE.WHITE: 25, 
    TowerDefenseEnum.PACKET_TYPE.GOLD: 25, 
    TowerDefenseEnum.PACKET_TYPE.DIAMOND: 25, 
    TowerDefenseEnum.PACKET_TYPE.COLOUR: 25, 
    TowerDefenseEnum.PACKET_TYPE.STAR: 25, 
    TowerDefenseEnum.PACKET_TYPE.ORIGINAL: 25, 
    TowerDefenseEnum.PACKET_TYPE.ZOMBIE: 25, 
    TowerDefenseEnum.PACKET_TYPE.COVER: 25, 
    TowerDefenseEnum.PACKET_TYPE.GRAY: 25, 
}
@export var key: String = ""
@export var lockCost: bool = false
@export var skip: bool = false

func Execute(num: int, packet: TowerDefensePacketConfig) -> int:
    match method:
        "Increase":
            if packet.canChangeCost:
                num += amontDictionary[packet.type]
        "Decrease":
            num = num - amontDictionary[packet.type]
        "Set":
            num = amontDictionary[packet.type]
    return num
