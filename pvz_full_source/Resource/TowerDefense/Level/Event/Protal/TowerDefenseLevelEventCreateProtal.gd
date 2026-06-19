class_name TowerDefenseLevelEventCreateProtal extends TowerDefenseLevelEventBase

@export var protalShape: String = "Circle"
@export var posRange: Vector4i = Vector4i(3, 1, 9, 5)
@export var changeTime: float = 0.0

func GetName() -> String:
    return "LEVLE_EVENT_CREATE_PROTAL"

func Execute() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var portalFeature: TowerDefenseBattleFeaturePortal = GetPortalFeature()
    if !portalFeature:
        var currentControl = TowerDefenseManager.currentControl
        if currentControl:
            currentControl.AddFeature("Portal", {})
            portalFeature = GetPortalFeature()
    if portalFeature:
        portalFeature.ProtalCreate(protalShape, posRange, changeTime)

func Init(valueDictionary: Dictionary) -> void :
    protalShape = valueDictionary.get("Shape", "Circle")
    var posData: Dictionary = valueDictionary.get("PosRange", {})
    posRange = Vector4i(posData.get("x", -1), posData.get("y", -1), posData.get("z", -1), posData.get("w", -1))
    changeTime = valueDictionary.get("ChangeTime", 0.0)

func Export() -> Dictionary:
    return {
        "EventName": "CreateProtal", 
        "Value": {
            "Shape": protalShape, 
            "PosRange": {
                "x": posRange.x, 
                "y": posRange.y, 
                "z": posRange.z, 
                "w": posRange.w
            }, 
            "ChangeTime": changeTime
        }
    }

func GetProperty() -> Dictionary:
    var data = super.GetProperty()
    data["改变地图"] = {
        "地图": {
            "Object": self, 
            "Type": "Enum", 
            "Property": "protalShape", 
            "Hint": {
                "Circle": "Circle", 
                "Square": "Square", 
                "Rhombus": "Rhombus"
            }, 
            "Rest": "Circle"
        }, 
        "范围": {
            "Object": self, 
            "Type": "Vector4i", 
            "Property": "posRange", 
            "Rest": Vector4i(3, 1, 9, 5)
        }, 
        "位置改变时间": {
            "Object": self, 
            "Type": "Float", 
            "Property": "changeTime", 
            "Rest": 0.0
        }
    }
    return data

func GetPortalFeature() -> TowerDefenseBattleFeaturePortal:
    var currentControl = TowerDefenseManager.currentControl
    if currentControl:
        return currentControl.GetFeature("Portal")
    return null
