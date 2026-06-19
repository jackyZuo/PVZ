@tool
class_name TowerDefenseLevelNewConfig extends TowerDefenseLevelBaseConfig

@export var data: JSON:
    set(_data):
        data = _data
        Init()
@export var version: StringName = "1.0"
@export var featureData: Dictionary[StringName, Dictionary]
@export var processName: StringName
@export var processData: Dictionary

func Init() -> void :
    if !data:
        return
    var levelData: Dictionary = data.data as Dictionary
    name = levelData.get("Name", "")
    levelName = levelData.get("LevelName", "")
    description = levelData.get("Description", "")
    levelNumber = levelData.get("LevelNumber", 0)
    nextLevel = levelData.get("NextLevel", "")
    homeWorld = GeneralEnum.HOMEWORLD.get(levelData.get("HomeWorld", "NOONE").to_upper())
    version = levelData.get("Version", "1.0")
    var processDict: Dictionary = levelData.get("Process", {})
    if !processDict.is_empty():
        processName = processDict.get("Name", "")
        processData = processDict.get("Data", {})
    featureData.clear()
    var featureArray: Array = levelData.get("Feature", [])
    for feature: Dictionary in featureArray:
        var featureName: StringName = feature.get("Name", "")
        var featureDict: Dictionary = feature.get("Data", {})
        featureData[featureName] = featureDict

func Export() -> Dictionary:
    var _data: Dictionary = {
        "Name": name, 
        "LevelName": levelName, 
        "Description": description, 
        "LevelNumber": levelNumber, 
        "NextLevel": nextLevel, 
        "HomeWorld": GeneralEnum.HOMEWORLD.find_key(homeWorld), 
        "Version": version, 
        "Feature": [], 
        "Process": {}
    }
    for featureName: StringName in featureData:
        _data["Feature"].append({"Name": featureName, "Data": featureData[featureName]})
    if processName != &"":
        _data["Process"] = {"Name": processName, "Data": processData}
    return _data
