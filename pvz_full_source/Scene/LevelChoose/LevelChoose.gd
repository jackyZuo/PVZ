extends Control

enum MODE{
    CHAPTER, 
    LEVEL, 
    OPTION, 
}


const LEVEL_SELECT_ITEM = preload("uid://cp8mgtcrcrxwf")
const DRAG_MENU_SELECT_ITEMLEVEL = preload("uid://bftr1dw41t3pu")
const DRAG_MENU_SELECT_ITEM_CHAPTER = preload("uid://rsb7ubyly6ta")

@onready var camera: Camera2D = %Camera
@onready var levelChooseMarker: Marker2D = %LevelChooseMarker
@onready var defaultMarker: Marker2D = %DefaultMarker

@onready var gui: CanvasLayer = %GUI
@onready var guiFollow: CanvasLayer = %GUIFollow
@onready var optionGui: CanvasLayer = %OptionGUI

@onready var informationLabel: Label = %InformationLabel

@onready var chapterMenu: = %ChapterMenu
@onready var levelMenu: DragMenu = %LevelMenu

@onready var normalButton: TextureButton = %NormalButton
@onready var difficultButton: TextureButton = %DifficultButton
@onready var normalLabel: Label = %NormalLabel
@onready var difficultLabel: Label = %DifficultLabel

@onready var levelMenuFlattenCheckBox: CheckBox = %LevelMenuFlattenCheckBox

@onready var chapterTexture: TextureRect = %ChapterTexture
@onready var chapterSelectBackground: TextureRect = %ChapterSelectBackground
@onready var levelMenuFlatten: Control = %LevelMenuFlatten
@onready var levelContainer: HFlowContainer = %LevelContainer

var currentChapterList: Array
var currentChapter: Dictionary
var currentChapterIndex: int = -1

var currentMode: MODE = MODE.CHAPTER
var saveBackMode: MODE = MODE.CHAPTER
var tween: Tween

func _ready() -> void :
    AudioManager.AudioPlay("ZenGarden", AudioManagerEnum.TYPE.MUSIC)
    currentChapterList = ResourceManager.LEVELS[Global.currentLevelChoose]["Chapter"]
    InitChapter()
    if Global.currentAwardMode:
        Global.currentAwardMode = false
        var chapterIndex: int = GameSaveManager.GetKeyValue("AdventureChapterIndex")
        if chapterIndex != -1:
            Select(chapterIndex)
    elif Global.currentChapterId != -1 && Global.enterLevelMode == "LevelChoose":
        Select(Global.currentChapterId)

    normalLabel.modulate = Color.WHITE
    difficultLabel.modulate = Color.WHITE
    match GameSaveManager.GetKeyValue("CurrentDifficult"):
        "Normal":
            normalButton.button_pressed = true
            normalLabel.modulate = Color.GREEN
        "Difficult":
            difficultButton.button_pressed = true
            difficultLabel.modulate = Color.ORANGE_RED
        _:
            GameSaveManager.SetKeyValue("CurrentDifficult", "Normal")
            normalButton.button_pressed = true
            normalLabel.modulate = Color.GREEN

    levelMenuFlattenCheckBox.button_pressed = GameSaveManager.GetKeyValue("LevelMenuFlatten")
    if levelMenuFlattenCheckBox.button_pressed:
        levelMenu.visible = false
        levelMenuFlatten.visible = true
        gui.follow_viewport_enabled = true
    else:
        levelMenu.visible = true
        levelMenuFlatten.visible = false
        gui.follow_viewport_enabled = false

func InitChapter() -> void :
    for chapterId in range(currentChapterList.size()):
        var chapter: Dictionary = currentChapterList[chapterId]
        var item: DragMenuSelectItem = DRAG_MENU_SELECT_ITEM_CHAPTER.instantiate()
        item.index = chapterId
        item.select.connect(Select)
        chapterMenu.add_child(item)
        item.Init(chapter)
        if chapter["OpenKey"] == "":
            item.sprite.texture = load(chapter["UnlockImage"])
            continue
        var levelData: Dictionary = GameSaveManager.GetLevelValue(chapter["OpenKey"])
        if levelData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0 || CommandManager.debugOpenAllLevel:
            item.sprite.texture = load(chapter["UnlockImage"])
        else:
            item.sprite.texture = load(chapter["LockImage"])
            item.lock = true

func InitLevel(chapterId: int) -> void :
    currentChapter = currentChapterList[chapterId]
    if currentChapter.get("Background", "") != "":
        chapterTexture.texture = load(currentChapter["Background"])
    if currentChapter.get("Building", "") != "":
        chapterSelectBackground.texture = load(currentChapter["Building"])
    var preOpen = currentChapter.get_or_add("PreOpen", 0) - 1
    var levelList = currentChapter["Level"]
    for levelListId in range(levelList.size()):
        var level: Dictionary = levelList[levelListId]
        if level["OpenKey"] == "Lock":
            continue
        var levelData: Dictionary = GameSaveManager.GetLevelValue(level["OpenKey"])
        if !CommandManager.debugOpenAllLevel && !(level["OpenKey"] == "" || levelData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0):
            if preOpen <= 0:
                continue
            else:
                preOpen -= 1
        var item = DRAG_MENU_SELECT_ITEMLEVEL.instantiate()
        item.index = levelListId
        item.select.connect(Select)
        levelMenu.add_child(item)
        if currentChapter["Level"][levelListId]["SaveKey"] != "":
            item.Init(level["SaveKey"])
        item.sprite.texture = load(level["UnlockImage"])

        var itemFlatten = DRAG_MENU_SELECT_ITEMLEVEL.instantiate()
        itemFlatten.index = levelListId
        itemFlatten.select.connect(Select)
        levelContainer.add_child(itemFlatten)
        itemFlatten.graphics.scale = Vector2.ONE * 0.5
        if currentChapter["Level"][levelListId]["SaveKey"] != "":
            itemFlatten.Init(level["SaveKey"])
        itemFlatten.sprite.texture = load(level["UnlockImage"])

    var levelIndex: int = GameSaveManager.GetKeyValue("AdventureChapter%dIndex" % [chapterId + 1])
    if levelIndex != -1:
        levelMenu.SetPos.call_deferred(levelIndex)

func Select(id: int) -> void :
    if tween && tween.is_running():
        return
    match currentMode:
        MODE.CHAPTER:
            if currentChapterList[id].get("Lock", false):
                var dialog = DialogManager.DialogCreate("DialogBoxTips")
                dialog.text = "[center][font_size=24]敬请期待[/font_size][/center]"
                return
            currentChapterIndex = id
            Global.currentChapterId = id
            GameSaveManager.SetKeyValue("AdventureChapterIndex", id)
            chapterMenu.alive = false
            tween = camera.create_tween()
            tween.set_ease(Tween.EASE_IN_OUT)
            tween.set_trans(Tween.TRANS_QUAD)
            tween.tween_property(camera, "global_position:y", levelChooseMarker.global_position.y, 0.5)
            currentMode = MODE.LEVEL
            InitLevel(id)
            informationLabel.text = currentChapter["Name"]
        MODE.LEVEL:
            var difficult: String = GameSaveManager.GetKeyValue("CurrentDifficult")
            chapterMenu.alive = true
            GameSaveManager.SetKeyValue("AdventureChapter%dIndex" % [currentChapterIndex + 1], id)
            GameSaveManager.Save()
            if currentChapter["Level"][id]["Level"][difficult] != "":
                TowerDefenseManager.currentLevelConfig = load(currentChapter["Level"][id]["Level"][difficult])
            else:
                TowerDefenseManager.currentLevelConfig = load(currentChapter["Level"][id]["Level"]["Normal"])
            var modLevelFind: String = ModManager.FindLevel(Global.currentLevelChoose, Global.currentChapterId, id, difficult)
            if modLevelFind != "":
                TowerDefenseManager.currentLevelConfig = load(modLevelFind)
            Global.currentLevelId = id
            Global.enterLevelMode = "LevelChoose"
            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                MultiPlayerManager.SendSelectLevel(currentChapter["Level"][id]["SaveKey"])
                MultiPlayerManager.SendLevelConfig()
                MultiPlayerManager.ResetLevelConfigAck()
                if !MultiPlayerManager.CheckAllLevelConfigAcked():
                    await MultiPlayerManager.all_level_config_acked
                MultiPlayerManager.SendStartGame()
                return
            SceneManager.ChangeScene("TowerDefense")

func Back() -> void :
    match currentMode:
        MODE.CHAPTER:
            GameSaveManager.Save()
            if Global.currentLevelChoose in ["MiniGames", "Puzzle", "IZM2"]:
                Global.mainMenuShowMoreModes = true
            SceneManager.ChangeScene("MainMenu")
        MODE.LEVEL:
            informationLabel.text = "章节选择"
            tween = camera.create_tween()
            tween.set_ease(Tween.EASE_IN_OUT)
            tween.set_trans(Tween.TRANS_QUAD)
            tween.tween_property(camera, "global_position:y", defaultMarker.global_position.y, 0.5)
            currentMode = MODE.CHAPTER
            chapterMenu.alive = true
            await tween.finished
            for item in levelMenu.get_children():
                item.queue_free()
            for item in levelContainer.get_children():
                item.queue_free()
        MODE.OPTION:
            gui.visible = true
            guiFollow.visible = true
            optionGui.visible = false
            currentMode = saveBackMode

func OptionButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    saveBackMode = currentMode
    currentMode = MODE.OPTION
    gui.visible = false
    guiFollow.visible = false
    optionGui.visible = true

func DifficultChange() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    var difficult: String = "Normal"
    normalLabel.modulate = Color.WHITE
    difficultLabel.modulate = Color.WHITE
    var flag: bool = false
    if normalButton.button_pressed:
        difficult = "Normal"
        normalLabel.modulate = Color.GREEN
        flag = true
    if difficultButton.button_pressed:
        DialogManager.DialogCreate("DifficultWarning")
        difficult = "Difficult"
        difficultLabel.modulate = Color.ORANGE_RED
        flag = true
    if !flag:
        difficult = "Normal"
        normalLabel.modulate = Color.GREEN
        flag = true
    GameSaveManager.SetKeyValue("CurrentDifficult", difficult)
    GameSaveManager.Save()

func LevelMenuFlattenCheckBoxToggled(toggle: bool) -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    if toggle:
        levelMenu.visible = false
        levelMenuFlatten.visible = true
        gui.follow_viewport_enabled = true
    else:
        levelMenu.visible = true
        levelMenuFlatten.visible = false
        gui.follow_viewport_enabled = false
    GameSaveManager.SetKeyValue("LevelMenuFlatten", toggle)
    GameSaveManager.Save()
