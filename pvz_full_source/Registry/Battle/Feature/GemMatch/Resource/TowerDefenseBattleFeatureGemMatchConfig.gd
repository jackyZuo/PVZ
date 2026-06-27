class_name TowerDefenseBattleFeatureGemMatchConfig extends Resource

@export var boardRows: int = 5
@export var boardCols: int = 9
@export var plantList: Array[StringName] = []
@export var sunPerMatch: int = 25
@export var fallSpeed: float = 300.0
@export var plantUpgradeList: Array[Dictionary] = []
@export var fillHoleCost: int = 200


var _upgradeMap: Dictionary = {}

func Init(data: Dictionary) -> void :
    boardRows = data.get("boardRows", 5)
    boardCols = data.get("boardCols", 9)
    var plants: Array = data.get("plantList", [])
    for p in plants:
        plantList.append(StringName(p))
    sunPerMatch = data.get("sunPerMatch", 25)
    fallSpeed = data.get("fallSpeed", 300.0)
    fillHoleCost = int(data.get("fillHoleCost", 200))
    var upgrades: Array = data.get("plantUpgradeList", [])
    for item in upgrades:
        var d: Dictionary = item
        plantUpgradeList.append(d)
        var fromKey: StringName = StringName(d.get("from", ""))
        var toKey: StringName = StringName(d.get("to", ""))
        var cost: int = int(d.get("cost", 0))
        if fromKey != "" && toKey != "":
            _upgradeMap[fromKey] = {to = toKey, cost = cost}

func GetUpgradeTarget(characterKey: StringName) -> StringName:
    var info: Dictionary = _upgradeMap.get(characterKey, {})
    return info.get("to", "")

func GetUpgradeCost(characterKey: StringName) -> int:
    var info: Dictionary = _upgradeMap.get(characterKey, {})
    return info.get("cost", 0)

func GetUpgradeSource(targetKey: StringName) -> StringName:
    for key in _upgradeMap.keys():
        var info: Dictionary = _upgradeMap[key]
        if info.get("to", "") == targetKey:
            return key
    return ""
