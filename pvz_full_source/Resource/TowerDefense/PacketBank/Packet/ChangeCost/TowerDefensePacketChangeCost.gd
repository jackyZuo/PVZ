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

func ExportSave() -> Dictionary:
    var amountDict: Dictionary = {}
    for pktType: TowerDefenseEnum.PACKET_TYPE in amontDictionary.keys():
        amountDict[pktType] = amontDictionary[pktType]
    return {
        "method": method, 
        "amontDictionary": amountDict, 
        "key": key, 
        "lockCost": lockCost, 
        "skip": skip, 
    }

static func ImportSave(data: Dictionary) -> TowerDefensePacketChangeCost:
    var changeCost: TowerDefensePacketChangeCost = TowerDefensePacketChangeCost.new()
    changeCost.method = data.get("method", "Increase")
    var amountDict: Dictionary = data.get("amontDictionary", {})
    for pktType: int in amountDict.keys():
        changeCost.amontDictionary[pktType as TowerDefenseEnum.PACKET_TYPE] = amountDict[pktType]
    changeCost.key = data.get("key", "")
    changeCost.lockCost = data.get("lockCost", false)
    changeCost.skip = data.get("skip", false)
    return changeCost
