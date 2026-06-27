class_name TowerDefenseCharacterEventPacketSpawn extends TowerDefenseCharacterEventBase

@export var packetName: String = ""
@export var percentage: float = 1.0
@export var dieSpawn: bool = false
@export var byCamp: bool = false
@export var characterOverride: TowerDefenseCharacterOverride

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, packetName, percentage, dieSpawn, byCamp, target.camp, characterOverride)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, packetName, percentage, dieSpawn, byCamp, target.camp, characterOverride)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, packetName, percentage, dieSpawn, byCamp, projectile.camp, characterOverride)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    packetName = valueDictionary.get("PacketName", "")
    percentage = valueDictionary.get("Percentage", 1.0)
    dieSpawn = valueDictionary.get("DieSpawn", false)
    byCamp = valueDictionary.get("ByCamp", false)
    var characterOverrideData: Dictionary = valueDictionary.get("CharacterOverride", {})
    if !characterOverrideData.is_empty():
        characterOverride = TowerDefenseCharacterOverride.new()
        characterOverride.Init(characterOverrideData)

func Export() -> Dictionary:
    var data = {
        "EventName": "PacketSpawn", 
        "Value": {
            "PacketName": packetName, 
            "Percentage": percentage, 
            "DieSpawn": dieSpawn, 
            "ByCamp": byCamp
        }
    }
    if is_instance_valid(characterOverride):
        data["Value"]["CharacterOverride"] = characterOverride.Export()
    return data

static func Run(target: TowerDefenseCharacter, _packetName: String, _percentage: float, _dieSpawn: bool = false, _byCamp: bool = false, _sourceCamp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT, _characterOverride: TowerDefenseCharacterOverride = null) -> void :
    if randf() > _percentage:
        return
    if !_dieSpawn || (_dieSpawn && (target.instance.die || target.instance.nearDie)):
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(_packetName)
        if is_instance_valid(packetConfig):
            if is_instance_valid(_characterOverride):
                if !is_instance_valid(packetConfig.override):
                    packetConfig.override = TowerDefensePacketOverride.new()
                packetConfig.override.characterOverride = _characterOverride
            var plant: TowerDefenseCharacter = packetConfig.Plant(target.gridPos)
            if is_instance_valid(plant):
                if _byCamp && plant.camp != _sourceCamp:
                    plant.Hypnoses()
