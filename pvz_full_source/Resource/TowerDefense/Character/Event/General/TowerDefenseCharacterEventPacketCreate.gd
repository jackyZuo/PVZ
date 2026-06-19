class_name TowerDefenseCharacterEventPacketCreate extends TowerDefenseCharacterEventBase

@export var packetName: String = ""
@export var aliveTime: float = 15.0
@export var useCost: bool = false

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, packetName, aliveTime, useCost)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, packetName, aliveTime, useCost)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, packetName, aliveTime, useCost)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    packetName = valueDictionary.get("PacketName", "")
    aliveTime = valueDictionary.get("AliveTime", 15.0)
    useCost = valueDictionary.get("UseCost", false)


func Export() -> Dictionary:
    return {
        "EventName": "PacketCreate", 
        "Value": {
            "PacketName": packetName, 
            "AliveTime": aliveTime, 
            "UseCost": useCost
        }
    }

static func Run(target: TowerDefenseCharacter, _packetName: String, _aliveTime: float = 8, _useCost: bool = false) -> void :
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(_packetName)
    TowerDefenseManager.SpawnPacket(packetConfig, target.global_position, _aliveTime, false, _useCost)
    var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    packet.showCost = _useCost
    packet.aliveTime = _aliveTime
