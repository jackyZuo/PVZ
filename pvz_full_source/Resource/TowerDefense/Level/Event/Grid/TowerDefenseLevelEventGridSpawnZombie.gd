class_name TowerDefenseLevelEventGridSpawnZombie extends TowerDefenseLevelEventBase

@export var zombieNames: Array = ["ZombieNormal", "ZombieNormalCone", "ZombieNormalBucket"]
@export var zombieNum: int = 5
@export var delay: Vector2 = Vector2(-1, -1)
@export var override: TowerDefenseCharacterOverride
@export var spawnPos: Vector4i = Vector4i(3, 1, 9, 5)
@export var spawnType: String = "Default"

func GetName() -> String:
    return "LEVLE_EVENT_GRID_SPAWN_ZOMBIE"

func Execute() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    TowerDefenseBattleFeatureWave.instance.GridSpawnZombie(zombieNames, zombieNum, delay, override, spawnPos, spawnType)

func Init(valueDictionary: Dictionary) -> void :
    zombieNames = valueDictionary.get("ZombieNames", [])
    zombieNum = valueDictionary.get("ZombieNum", 1)
    var delayGet = valueDictionary.get("Delay", [-1, -1])
    if delayGet is Array:
        if delayGet.size() == 2:
            delay = Vector2(delayGet[0], delayGet[1])
        elif delayGet.size() == 1:
            delay = Vector2(delayGet[0], delayGet[0])
    if delayGet is float:
        delay = Vector2.ONE * delayGet
    var overrideData = valueDictionary.get("Override", {}) as Dictionary
    if !overrideData.is_empty():
        override = TowerDefenseCharacterOverride.new()
        override.Init(overrideData)
    var posData: Dictionary = valueDictionary.get("SpawnPos", {})
    spawnPos = Vector4i(posData.get("x", -1), posData.get("y", -1), posData.get("z", -1), posData.get("w", -1))
    spawnType = valueDictionary.get("SpawnType", "Default")

func Export() -> Dictionary:
    var data = {
        "EventName": "GridSpawnZombie", 
        "Value": {
            "ZombieNames": zombieNames, 
            "ZombieNum": zombieNum, 
            "Delay": [delay.x, delay.y], 
            "SpawnPos": {
                "x": spawnPos.x, 
                "y": spawnPos.y, 
                "z": spawnPos.z, 
                "w": spawnPos.w
            }, 
            "SpawnType": spawnType
        }
    }
    if is_instance_valid(override):
        data["Value"]["Override"] = override.Export()
    return data

func GetProperty() -> Dictionary:
    var data = super.GetProperty()
    data["图格生成僵尸"] = {
        "数量": {
            "Object": self, 
            "Type": "Int", 
            "Property": "zombieNum", 
            "Rest": 5
        }, 
        "延时范围": {
            "Object": self, 
            "Type": "Vector2", 
            "Property": "delay", 
            "Rest": Vector2(-1, -1)
        }, 
        "范围": {
            "Object": self, 
            "Type": "Vector4i", 
            "Property": "spawnPos", 
            "Rest": Vector4i(3, 1, 9, 5)
        }, 
        "放置类型": {
            "Object": self, 
            "Type": "String", 
            "Property": "spawnType", 
            "Rest": "Default"
        }
    }
    return data
