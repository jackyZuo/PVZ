class_name TowerDefenseCharacterEventPacketSpawn extends TowerDefenseCharacterEventBase

@export var packetName: String = ""
@export var percentage: float = 1.0
@export var dieSpawn: bool = false
@export var byCamp: bool = false

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, packetName, percentage, dieSpawn, byCamp)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, packetName, percentage, dieSpawn, byCamp)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, packetName, percentage, dieSpawn, byCamp)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    packetName = valueDictionary.get("PacketName", "")
    percentage = valueDictionary.get("Percentage", 1.0)
    dieSpawn = valueDictionary.get("DieSpawn", false)
    byCamp = valueDictionary.get("ByCamp", false)

func Export() -> Dictionary:
    return {
        "EventName": "PacketSpawn", 
        "Value": {
            "PacketName": packetName, 
            "Percentage": percentage, 
            "DieSpawn": dieSpawn, 
            "ByCamp": byCamp
        }
    }

static func Run(target: TowerDefenseCharacter, _packetName: String, _percentage: float, _dieSpawn: bool = false, _byCamp: bool = false) -> void :
    if randf() > _percentage:
        return
    if !_dieSpawn || (_dieSpawn && (target.instance.die || target.instance.nearDie)):
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(_packetName)
        if is_instance_valid(packetConfig):
            var plant: TowerDefenseCharacter = packetConfig.Plant(target.gridPos)
            if is_instance_valid(plant):
                if _byCamp && target.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
                    plant.Hypnoses()
