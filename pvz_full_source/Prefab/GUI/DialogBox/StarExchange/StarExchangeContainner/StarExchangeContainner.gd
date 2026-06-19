extends Control

const STAR_EXCHANGE_ITEM = preload("uid://byuv6jflrtcul")

@onready var chapterTexture: TextureRect = %ChapterTexture
@onready var finishNumLabel: Label = %FinishNumLabel

@onready var itemContainer: HBoxContainer = %ItemContainer

var data: Dictionary

var finishNum: int = 0

func Init(_data: Dictionary) -> void :
    data = _data
    chapterTexture.texture = load(data["ChapterImage"])

    finishNum = TowerDefenseManager.GetLevelChapterFinishNum(data["LevelList"], data["Chapter"])

    finishNumLabel.text = "x%d" % finishNum

    var awardList = data["Award"]
    for awardData in awardList:
        AddItem(awardData)

func AddItem(_data: Dictionary) -> void :
    var item: StarExchangeItem = STAR_EXCHANGE_ITEM.instantiate()
    itemContainer.add_child(item)
    item.Init(_data, finishNum)
