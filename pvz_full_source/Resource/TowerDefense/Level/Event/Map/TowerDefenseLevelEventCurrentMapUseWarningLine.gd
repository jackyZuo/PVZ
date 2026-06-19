class_name TowerDefenseLevelEventCurrentMapUseWarningLine extends TowerDefenseLevelEventBase

@export var row: int = 5

func GetName() -> String:
    return "LEVLE_EVENT_CURRENTMAP_USE_WARNINGLINE"

func Execute() -> void :
    var warningLineFeature: TowerDefenseBattleFeatureWarningLine = GetWarningLineFeature()
    if !warningLineFeature:
        var currentControl = TowerDefenseManager.currentControl
        if currentControl:
            currentControl.AddFeature("WarningLine", {})
            warningLineFeature = GetWarningLineFeature()
    if warningLineFeature:
        warningLineFeature.AddWarningLine(row)

func Init(valueDictionary: Dictionary) -> void :
    row = valueDictionary.get("Row", [])

func Export() -> Dictionary:
    return {
        "EventName": "CurrentMapUseWarningLine", 
        "Value": {
            "Row": row
        }
    }

func GetProperty() -> Dictionary:
    var data = super.GetProperty()
    data["使用警戒线"] = {
        "列": {
            "Object": self, 
            "Type": "Int", 
            "Property": "row", 
            "Rest": 5
        }
    }
    return data

func GetWarningLineFeature() -> TowerDefenseBattleFeatureWarningLine:
    var currentControl = TowerDefenseManager.currentControl
    if currentControl:
        return currentControl.GetFeature("WarningLine")
    return null
