class_name TowerDefenseLevelPreSpawnConfig extends Resource

@export var packetName: String
@export var gridPos: Vector2i
@export var characterOverride: TowerDefenseCharacterOverride

func Init(spawnDictionary: Dictionary):
    packetName = spawnDictionary.get_or_add("Name", null)
    var gridPosGet = spawnDictionary.get_or_add("GridPos", [0, 0])
    gridPos = Vector2i(gridPosGet[0], gridPosGet[1])
    characterOverride = TowerDefenseCharacterOverride.new()
    characterOverride.Init(spawnDictionary.get_or_add("CharacterOverride", {}))

func SpawnCharacter(_gridPos: Vector2 = gridPos) -> TowerDefenseCharacter:
    var packet: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
    var character: TowerDefenseCharacter = packet.Plant(_gridPos, false, true)
    return character

func Export() -> Dictionary:
    var data: Dictionary = {
        "Name": packetName, 
        "GridPos": [gridPos.x, gridPos.y]
    }
    if is_instance_valid(characterOverride):
        data["CharacterOverride"] = characterOverride.Export()
    return data
