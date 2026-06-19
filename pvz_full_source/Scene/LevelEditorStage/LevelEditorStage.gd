extends Control

const LEVEL_EDITOR_PANEL_BUTTON_GROUP = preload("uid://clop83geu1mo3")
const LEVEL_EDITOR_MY_LEVEL_ITEM = preload("uid://jtdmoji4acxv")

const PATH: String = "user://Diy"

@onready var levelEditorStageTop: TextureRect = %LevelEditorStageTop
@onready var levelEditorStageLeft: TextureRect = %LevelEditorStageLeft
@onready var levelEditorStageRight: TextureRect = %LevelEditorStageRight

@onready var levelEditorChooseLayer: CanvasLayer = %LevelEditorChooseLayer
@onready var levelEditorMyLevelLayer: CanvasLayer = %LevelEditorMyLevelLayer
@onready var levelEditorOnlineLevelLayer: CanvasLayer = %LevelEditorOnlineLevelLayer
@onready var levelEditorLayer: CanvasLayer = %LevelEditorLayer
@onready var levelEditorBattleLayer: CanvasLayer = %LevelEditorBattleLayer
@onready var levelEditorQuizLayer: CanvasLayer = %LevelEditorQuizLayer

@onready var levelEditorInformationEditor: LevelEditorInformationEditor = %LevelEditorInformationEditor
@onready var levelEditorEventEditor: LevelEditorEventEditor = %LevelEditorEventEditor
@onready var levelEditorMapEditor: LevelEditorMapEditor = %LevelEditorMapEditor
@onready var levelEditorSeedbankEditor: LevelEditorSeedbankEditor = %LevelEditorSeedbankEditor
@onready var levelEditorWaveEditor: LevelEditorWaveEditor = %LevelEditorWaveEditor

@onready var levelEditorBattle: LevelEditorBattle = %LevelEditorBattle
@onready var levelEditorQuiz: Control = %LevelEditorQuiz

@onready var levelInformationButton: MainButton = %LevelInformationButton
@onready var levelEventButton: MainButton = %LevelEventButton
@onready var levelMapButton: MainButton = %LevelMapButton
@onready var levelSeedbankButton: MainButton = %LevelSeedbankButton
@onready var levelWaveButton: MainButton = %LevelWaveButton
@onready var myLevelContainer: HFlowContainer = %MyLevelContainer

@onready var levelEditorOnlineLevel: Control = %LevelEditorOnlineLevel

@export var levelConfig: TowerDefenseLevelConfig

static var showTips: bool = false

var currentUid: String = ""
var levelUid: Array[String] = []

var skip: bool = false

var over: bool = false

func Init(_levelConfig: TowerDefenseLevelConfig) -> void :
    levelConfig = _levelConfig
    levelEditorInformationEditor.Init(levelConfig)
    levelEditorEventEditor.Init(levelConfig)
    levelEditorMapEditor.Init(levelConfig)
    levelEditorSeedbankEditor.Init(levelConfig)
    levelEditorWaveEditor.Init(levelConfig)

func _enter_tree() -> void :
    if Global.isEditor && Global.enterLevelMode == "DiyLevel":
        skip = true
        currentUid = Global.currentDiyLevelUid
        Global.enterLevelMode = ""
    Global.isEditor = true

func _ready() -> void :
    AudioManager.AudioPlay("ZenGarden", AudioManagerEnum.TYPE.MUSIC)

    if !DirAccess.dir_exists_absolute(PATH):
        DirAccess.make_dir_recursive_absolute(PATH)
    for fileName in DirAccess.get_files_at(PATH):
        levelUid.append(fileName.get_basename())

    AnimeEnter()

    levelInformationButton.button_group = LEVEL_EDITOR_PANEL_BUTTON_GROUP
    levelEventButton.button_group = LEVEL_EDITOR_PANEL_BUTTON_GROUP
    levelMapButton.button_group = LEVEL_EDITOR_PANEL_BUTTON_GROUP
    levelSeedbankButton.button_group = LEVEL_EDITOR_PANEL_BUTTON_GROUP
    levelWaveButton.button_group = LEVEL_EDITOR_PANEL_BUTTON_GROUP

    if skip:
        Init(TowerDefenseManager.currentLevelConfig)
        LevelDiyButtonPressed(false)
    else:
        if !showTips:
            DialogManager.DialogCreate("LevelEditorTips")
            showTips = true

    if Global.enterLevelIsBattle:
        if !Global.enterLevelIsBattleFinish:

            GameSaveManager.SetKeyValue("LevelEditorBattleFailNum", GameSaveManager.GetKeyValue("LevelEditorBattleFailNum") + 1)
        else:
            GameSaveManager.SetKeyValue("LevelEditorBattleFinishNum", GameSaveManager.GetKeyValue("LevelEditorBattleFinishNum") + 1)
        GameSaveManager.SetKeyValue("LevelEditorBattleCurrentLevel", "-1")
        GameSaveManager.Save()
        Global.enterLevelIsBattleFinish = false
        Global.enterLevelIsBattle = false
        LevelBattleButtonPressed()
    elif Global.enterLevelId != "-1":
        LevelOnlineButtonPressed()

    if Global.enterLevelId != "-1":
        var dialog = DialogManager.DialogCreate("OnlineLevelPreview")
        dialog.InitDialog(Global.enterLevelId)
        dialog.select.connect(levelEditorOnlineLevel.EnterLevel.bind(Global.enterLevelId))
        Global.enterLevelId = "-1"

func PanelChange() -> void :
    levelEditorInformationEditor.visible = levelInformationButton.button_pressed
    levelEditorEventEditor.visible = levelEventButton.button_pressed
    levelEditorMapEditor.visible = levelMapButton.button_pressed
    levelEditorSeedbankEditor.visible = levelSeedbankButton.button_pressed
    levelEditorWaveEditor.visible = levelWaveButton.button_pressed

func LevelMineButtonPressed() -> void :
    levelEditorChooseLayer.visible = false
    levelEditorMyLevelLayer.visible = true
    AnimeExit()
    levelUid.clear()
    for node in myLevelContainer.get_children():
        node.queue_free()
    var filesWithTime = []
    for fileName in DirAccess.get_files_at(PATH):
        var fileTime = FileAccess.get_modified_time(PATH.path_join(fileName))
        filesWithTime.append({
            "fileName": fileName, 
            "fileTime": fileTime
        })
    filesWithTime.sort_custom( func(a, b): return a["fileTime"] > b["fileTime"])
    for file in filesWithTime:
        var myLevelItem = LEVEL_EDITOR_MY_LEVEL_ITEM.instantiate()
        myLevelItem.select.connect(MyLevelSelect)
        myLevelItem.delete.connect(MyLevelDelete)
        myLevelContainer.add_child(myLevelItem)
        myLevelItem.Init(file["fileName"].get_basename())
        levelUid.append(file["fileName"].get_basename())

func MyLevelSelect(uid: String) -> void :
    levelEditorMyLevelLayer.visible = false
    var filePath: String = PATH + "/" + uid + ".tres"
    if FileAccess.file_exists(filePath):
        var res = load(filePath)
        if res is TowerDefenseLevelConfig:
            currentUid = uid
            Init(res)
            LevelDiyButtonPressed(false, true)

func MyLevelDelete(uid: String) -> void :
    var filePath: String = PATH + "/" + uid + ".tres"
    if FileAccess.file_exists(filePath):
        DirAccess.remove_absolute(filePath)
        levelUid.erase(uid)

func LevelOnlineButtonPressed() -> void :
    levelEditorChooseLayer.visible = false
    levelEditorOnlineLevelLayer.visible = true
    AnimeExit()
    levelEditorOnlineLevel.GetPage()

func LevelDiyButtonPressed(init: bool = true, isLoad: bool = false) -> void :
    if init:















        var level = TowerDefenseLevelConfig.new()
        levelEditorChooseLayer.visible = false
        levelEditorLayer.visible = true
        var uid: int = randi()
        while levelUid.has(str(uid)):
            uid = randi()
        levelUid.append(str(uid))
        currentUid = str(uid)
        Init(level)
        Save()
        if !isLoad:
            AnimeExit()
    else:
        levelEditorChooseLayer.visible = false
        levelEditorLayer.visible = true
        if !isLoad:
            AnimeExit()

func LevelLoadButtonPressed() -> void :
    CommandManager.LoadLevelButtonPressed()

func LevelBattleButtonPressed() -> void :
    TowerDefenseManager.coinBank.Show(Vector2(450, 557), true)
    levelEditorChooseLayer.visible = false
    levelEditorBattle.Show()
    levelEditorBattleLayer.visible = true

func LevelQuizButtonPressed() -> void :
    levelEditorQuizLayer.visible = true
    levelEditorChooseLayer.visible = false

func LevelTestButtonPressed() -> void :
    if over:
        return
    Save()
    over = true
    Global.enterLevelMode = "DiyLevel"
    Global.currentDiyLevelUid = currentUid
    levelEditorLayer.visible = false
    TowerDefenseManager.currentLevelConfig = levelConfig
    SceneManager.ChangeScene("TowerDefense")

func Save() -> void :
    if over:
        return
    if is_instance_valid(levelEditorWaveEditor) && levelEditorWaveEditor.isLoading:
        await get_tree().process_frame
        if is_instance_valid(levelEditorWaveEditor) && levelEditorWaveEditor.isLoading:
            return
    levelEditorEventEditor.Save()
    levelEditorMapEditor.Save(true)
    levelEditorSeedbankEditor.Save()
    levelEditorWaveEditor.Save()
    ResourceSaver.save(levelConfig, PATH + "/" + currentUid + ".tres")

func Export() -> void :

    Save()
    DisplayServer.file_dialog_show("另存为项目", "", "", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, ["*.json"], SaveFileTo)







@warning_ignore("unused_parameter")
func SaveFileTo(status: bool, selected_paths: PackedStringArray, selected_filter_index: int) -> void :
    if selected_paths.size() < 1:
        return
    var _filePath: String = selected_paths[0]
    if _filePath.get_extension() != "json":
        _filePath += ".json"
    Save()
    var file = FileAccess.open(_filePath, FileAccess.WRITE_READ)
    file.store_string(JSON.stringify(levelConfig.Export()))
    file.close()

func LevelEditorBackButtonPressed() -> void :
    if levelEditorChooseLayer.visible:
        Global.isEditor = false
        Global.enterLevelIsBattle = false
        Global.enterLevelIsBattleFinish = false
        SceneManager.ChangeScene("MainMenu")
        return
    if levelEditorMyLevelLayer.visible:
        AnimeEnter()
        levelEditorChooseLayer.visible = true
        levelEditorMyLevelLayer.visible = false
        return
    if levelEditorOnlineLevelLayer.visible:
        AnimeEnter()
        levelEditorChooseLayer.visible = true
        levelEditorOnlineLevelLayer.visible = false
        return
    if levelEditorLayer.visible:
        levelInformationButton.button_pressed = true
        PanelChange()
        Save()
        levelEditorInformationEditor.Clear()
        levelEditorEventEditor.Clear()
        levelEditorMapEditor.Clear()
        levelEditorSeedbankEditor.Clear()
        levelEditorWaveEditor.Clear()
        AnimeEnter()
        levelEditorChooseLayer.visible = true
        levelEditorLayer.visible = false
        return

    if levelEditorBattleLayer.visible:
        if levelEditorBattle.overNode.visible:
            return
        if levelEditorBattle.tipsNode.visible:
            TowerDefenseManager.coinBank.Show(Vector2(450, 557), true)
            levelEditorBattle.tipsNode.visible = false
            levelEditorBattle.mainNode.visible = true
            return
        if levelEditorBattle.awardNode.visible:
            TowerDefenseManager.coinBank.Show(Vector2(450, 557), true)
            levelEditorBattle.awardNode.visible = false
            levelEditorBattle.mainNode.visible = true
            return
        if levelEditorBattle.historyNode.visible:
            TowerDefenseManager.coinBank.Show(Vector2(450, 557), true)
            levelEditorBattle.historyNode.visible = false
            levelEditorBattle.mainNode.visible = true
            return
        TowerDefenseManager.coinBank.Hide.call_deferred()
        levelEditorChooseLayer.visible = true
        levelEditorBattleLayer.visible = false
        return

    if levelEditorQuizLayer.visible:
        if levelEditorQuiz.mapChooseOver:
            return
        levelEditorQuizLayer.visible = false
        levelEditorChooseLayer.visible = true
        return

func AnimeExit() -> void :
    var view = get_viewport_rect()
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_trans(Tween.TRANS_QUART)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(levelEditorStageTop, ^"global_position", Vector2(0, -120), 0.5)
    tween.tween_property(levelEditorStageLeft, ^"global_position", Vector2(-300, 0), 0.5)
    tween.tween_property(levelEditorStageRight, ^"global_position", Vector2(view.position.x + view.size.x + 300, 0), 0.5)

func AnimeEnter() -> void :
    var view = get_viewport_rect()
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_trans(Tween.TRANS_QUART)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(levelEditorStageTop, ^"global_position", Vector2(0, 0), 0.5)
    tween.tween_property(levelEditorStageLeft, ^"global_position", Vector2(0, 0), 0.5)
    tween.tween_property(levelEditorStageRight, ^"global_position", Vector2(view.position.x + view.size.x - 200, 0), 0.5)
