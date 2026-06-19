@tool
class_name ShopItemConfig extends Resource

@export var type: String = ""
@export var stageList: Array[ShopItemStageConfig]

func Init(data: Dictionary) -> void :
    type = data.get("Type", "Item")
    var _stageList = data.get("Stage", [])
    for itemStageData: Dictionary in _stageList:
        var itemStageConfig: ShopItemStageConfig = ShopItemStageConfig.new()
        itemStageConfig.Init(itemStageData)
        stageList.append(itemStageConfig)
