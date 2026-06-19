class_name TowerDefenseBattleFeaturePreSpawnConfig extends Resource

@export var preSpawnList: Array[TowerDefenseLevelPreSpawnConfig] = []

func Init(data: Dictionary) -> void :
    Clear()
    var packetList: Array = data.get("Packet", []) as Array
    for packetData: Dictionary in packetList:
        var preSpawnConfig: TowerDefenseLevelPreSpawnConfig = TowerDefenseLevelPreSpawnConfig.new()
        preSpawnConfig.Init(packetData)
        preSpawnList.append(preSpawnConfig)

func Clear() -> void :
    preSpawnList.clear()
