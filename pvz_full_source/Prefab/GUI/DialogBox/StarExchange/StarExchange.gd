extends DialogBoxBase

const STAR_EXCHANGE_RESOURCE = preload("res://Asset/Config/StarExchange/StarExchangeResource.json")
const STAR_EXCHANGE_CONTAINNER = preload("uid://clhvbc3i3p6tf")

@onready var chapterContainer: VBoxContainer = %ChapterContainer

func _ready() -> void :
    var exchangeList = STAR_EXCHANGE_RESOURCE.data["Exchange"]
    for exchangeData in exchangeList:
        AddChapter(exchangeData)

func AddChapter(_data: Dictionary) -> void :
    var chapter = STAR_EXCHANGE_CONTAINNER.instantiate()
    chapterContainer.add_child(chapter)
    chapter.Init(_data)

func BackButtonPressed() -> void :
    Close()

func TryLevelButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    Global.enterTryLevelGroup = "Star"
    var dialog = DialogManager.DialogCreate("TryLevel")
    TowerDefenseManager.coinBank.Hide.call_deferred()
    visible = false
    await dialog.close
    visible = true
