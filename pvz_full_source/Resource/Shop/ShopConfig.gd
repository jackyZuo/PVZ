@tool
class_name ShopConfig extends Resource

@export var data: JSON:
    set(_data):
        data = _data
        Init()
        notify_property_list_changed()
@export var pageList: Array[ShopPageConfig]

func Init() -> void :
    pageList.clear()
    var _pageList = data.data["Page"]
    for pageData in _pageList:
        var pageConfig: ShopPageConfig = ShopPageConfig.new()
        pageConfig.Init(pageData)
        pageList.append(pageConfig)

func GetPageTypeList(type: String = "Total") -> Array[ShopPageConfig]:
    if type == "Total":
        return pageList
    var itemList: Array[ShopItemConfig] = []
    for pageConfig: ShopPageConfig in pageList:
        for item: ShopItemConfig in pageConfig.itemList:
            if item.type == type:
                itemList.append(item)
    var pageListGet: Array[ShopPageConfig] = []
    var pageConfig: ShopPageConfig
    for id in itemList.size():
        if id % 8 == 0:
            pageConfig = ShopPageConfig.new()
            pageListGet.append(pageConfig)
        pageConfig.itemList.append(itemList[id])
    return pageListGet
