class_name TowerDefenseLevelEventChangeProtalPos extends TowerDefenseLevelEventBase

func GetName() -> String:
    return "LEVLE_EVENT_CHAGE_PROTAL_POS"

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
        portalFeature.ProtalChangePos()

func Export() -> Dictionary:
    return {
        "EventName": "ChangeProtalPos", 
        "Value": {}
    }

func GetPortalFeature() -> TowerDefenseBattleFeaturePortal:
    var currentControl = TowerDefenseManager.currentControl
    if currentControl:
        return currentControl.GetFeature("Portal")
    return null
