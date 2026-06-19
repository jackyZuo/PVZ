class_name TowerDefenseLevelLookStarManagerConfig extends Resource

@export var open: bool = false
@export var checkList: Array[TowerDefenseLevelLookStarCheckConfig]

func Init(lookStarManagerData: Dictionary) -> void :
    open = lookStarManagerData.get("Open", false)

    var checkListGet = lookStarManagerData.get("Check", [])
    for checkData: Dictionary in checkListGet:
        var checkConfig: TowerDefenseLevelLookStarCheckConfig = TowerDefenseLevelLookStarCheckConfig.new()
        checkConfig.Init(checkData)
        checkList.append(checkConfig)

func Export() -> Dictionary:
    var data = {
        "Open": open, 
        "Check": []
    }
    for check: TowerDefenseLevelLookStarCheckConfig in checkList:
        data["Check"].append(check.Export())
    return data
