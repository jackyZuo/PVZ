class_name TowerDefenseLevelEventBungiSpawnZombie extends TowerDefenseLevelEventBase
const TOWER_DEFENSE_ZOMBIE_BUNGI_SPAWN = preload("uid://bkp73arbrdgkt")

@export var zombieNames: Array = ["ZombieNormal", "ZombieNormalCone", "ZombieNormalBucket"]
@export var zombieNum: int = 5
@export var delay: Vector2 = Vector2(-1, -1)
@export var override: TowerDefenseCharacterOverride
@export var spawnPos: Vector4i = Vector4i(3, 1, 9, 5)
@export var hypnoses: bool = false

func GetName() -> String:
    return "LEVLE_EVENT_BUNGI_SPAWN_ZOMBIE"

func Execute() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var weightPick: Array[WeightPickItemBase] = []
    if zombieNames.size() > 0:
        for zombieName: String in zombieNames:
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombieName)
            var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
            if characterConfig is TowerDefenseZombieConfig:
                var weight: int = characterConfig.weight
                if packetConfig.overrideWeight != -1:
                    weight = packetConfig.overrideWeight
                var weightPickItem: WeightPickItemBase = WeightPickItemBase.new(zombieName, weight)
                weightPick.append(weightPickItem)
        var cansSpawnPos: Array[Vector2i] = []
        for x in range(spawnPos.x, spawnPos.z + 1, 1):
            for y in range(spawnPos.y, spawnPos.w + 1, 1):
                cansSpawnPos.append(Vector2i(x, y))
        var num: int = min(cansSpawnPos.size(), zombieNum)
        var _cansSpawnPos: Array[Vector2i] = cansSpawnPos.duplicate()
        while (num > 0):
            var _weightPick = weightPick
            var _override = override
            var _hypnoses = hypnoses
            TowerDefenseManager.currentControl.get_tree().create_timer(randf_range(delay.x, delay.y), false).timeout.connect(
                func():
                    if _cansSpawnPos.size() <= 0:
                        return
                    var item: WeightPickItemBase = WeightPickMathine.Pick(_weightPick)
                    var gridPos: Vector2i = _cansSpawnPos.pick_random()
                    TowerDefenseManager.BungiSpawn(item.item, gridPos, _override, _hypnoses)
                    _cansSpawnPos.erase(gridPos)
            )
            num -= 1

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

    hypnoses = valueDictionary.get("Hypnoses", false)

func Export() -> Dictionary:
    var data = {
        "EventName": "BungiSpawnZombie", 
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
            "Hypnoses": hypnoses
        }
    }
    if is_instance_valid(override):
        data["Value"]["Override"] = override.Export()
    return data

func GetProperty() -> Dictionary:
    var data = super.GetProperty()
    data["随机蹦极放置墓碑僵尸"] = {
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
            "Property": "gravestonePos", 
            "Rest": Vector4i(3, 1, 9, 5)
        }, 
        "是否魅惑": {
            "Object": self, 
            "Type": "Bool", 
            "Property": "Hypnoses", 
            "Rest": false
        }
    }
    return data
