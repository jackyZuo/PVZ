class_name TowerDefenseCharacterEventDieSpawn extends TowerDefenseCharacterEventBase

@export var packetName: String = ""
@export var percentage: float = 1.0
@export var useGridPos: bool = true
@export var byCamp: bool = false
@export var offset: Vector2 = Vector2.ZERO

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(pos, target, packetName, percentage, useGridPos, byCamp, offset)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(pos, target, packetName, percentage, useGridPos, byCamp, offset)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target.global_position, target, packetName, percentage, useGridPos, byCamp, offset)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    packetName = valueDictionary.get("PacketName", "")
    percentage = valueDictionary.get("Percentage", 1.0)
    useGridPos = valueDictionary.get("UseGridPos", true)
    byCamp = valueDictionary.get("ByCamp", false)
    offset = valueDictionary.get("Offset", Vector2.ZERO)

func Export() -> Dictionary:
    return {
        "EventName": "DieSpawn", 
        "Value": {
            "PacketName": packetName, 
            "Percentage": percentage, 
            "UseGridPos": useGridPos, 
            "ByCamp": byCamp, 
            "Offset": offset
        }
    }

static func Run(pos: Vector2, target: TowerDefenseCharacter, _packetName: String, _percentage: float, _useGridPos: bool, _byCamp: bool, _offset: Vector2) -> void :
    if randf() > _percentage:
        return
    if !_packetName.is_empty():
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(_packetName)
        if is_instance_valid(packetConfig):
            var spawnPos: Vector2 = pos + _offset
            if _useGridPos:
                var plant: TowerDefenseCharacter = packetConfig.Plant(target.gridPos)
                if is_instance_valid(plant):
                    if _byCamp && target.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
                        plant.Hypnoses()
            else:
                var character: TowerDefenseCharacter = packetConfig.Create(spawnPos, target.gridPos, target.groundHeight)
                if is_instance_valid(character):
                    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                    characterNode.add_child(character)
                    if _byCamp && target.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
                        character.Hypnoses()
