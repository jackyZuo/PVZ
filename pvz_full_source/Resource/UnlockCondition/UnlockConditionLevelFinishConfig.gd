class_name UnlockConditionLevelFinishConfig extends UnlockConditionBaseConfig

@export var levelSaveKey: String = ""

func Check() -> bool:
    if levelSaveKey == "Unlock":
        return true
    var levelData: Dictionary = GameSaveManager.GetLevelValue(levelSaveKey)
    return levelData.get("Key", {}).get("Finish", 0.0) > 0
