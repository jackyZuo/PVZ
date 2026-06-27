class_name TowerDefenseLevelEventGravestoneSpawnZombie extends TowerDefenseLevelEventBase

@export var zombieNames: Array = ["ZombieNormal", "ZombieNormalCone", "ZombieNormalBucket"]
@export var zombieNum: int = 5
@export var delay: Vector2 = Vector2(-1, -1)
@export var override: TowerDefenseCharacterOverride

func GetName() -> String:
    return "LEVLE_EVENT_GRAVESTONE_SPAWN_ZOMBIE"

func Execute() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    TowerDefenseBattleFeatureWave.instance.GravestoneSpawn(zombieNames, zombieNum, delay, override)

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

func Export() -> Dictionary:
    var data = {
        "EventName": "GravestoneSpawnZombie", 
        "Value": {
            "ZombieNames": zombieNames, 
            "ZombieNum": zombieNum, 
            "Delay": [delay.x, delay.y], 
        }
    }
    if is_instance_valid(override):
        data["Value"]["Override"] = override.Export()
    return data

func GetProperty() -> Dictionary:
    var data = super.GetProperty()
    data["随机创建墓碑僵尸"] = {
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
        }
    }
    return data
