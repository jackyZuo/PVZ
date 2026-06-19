extends MenuDialogBase

@onready var handbookButton: MainButton = %HandbookButton
@onready var restartButton: MainButton = %RestartButton
@onready var mainMenuButton: MainButton = %MainMenuButton

@onready var levelEditorButton: MainButton = %LevelEditorButton

func _ready() -> void :
    super._ready()
    if Global.isEditor:
        levelEditorButton.visible = true
        handbookButton.visible = false
        mainMenuButton.visible = false
    if Global.enterLevelIsBattle:
        restartButton.visible = false
        mainMenuButton.visible = false

    if TowerDefenseManager.GetGameMethod() == TowerDefenseEnum.LEVEL_FINISH_METHOD.QUIZ:
        if TowerDefenseManager.IsGameRunning():
            restartButton.visible = false

    if Global.isMultiplayerMode:
        pasue = false
        if get_tree().paused:
            get_tree().paused = false
        restartButton.visible = false
        mainMenuButton.visible = false
        levelEditorButton.visible = false
        if !MultiPlayerManager.isHost:
            handbookButton.visible = false

func HandbookButtonPressed() -> void :
    if !Global.isMultiplayerMode:
        GameSaveManager.SaveLevelProgress(TowerDefenseManager.currentControl.levelConfig.name)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        MultiPlayerManager.SendMatchState(MatchOpCodes.GAME_RESULT, JSON.stringify({"leave": true}))
    match Global.enterLevelMode:
        "LevelChoose":
            if Global.currentLevelChoose != "TryLevel":
                SceneManager.ChangeScene("LevelChoose")
            else:
                SceneManager.ChangeScene("MainMenu")
        "DailyLevel":
            SceneManager.ChangeScene("MainMenu")
        "DiyLevel":
            SceneManager.ChangeScene("LevelEditorStage")
        "LoadLevel":
            SceneManager.ChangeScene("LevelEditorStage")
        "OnlineLevel":
            InternetServerManager.OnlineLevelPost(Global.enterLevelId, "abandon")
            if Global.enterLevelIsBattle:
                Global.enterLevelIsBattleFinish = false
            SceneManager.ChangeScene("LevelEditorStage")

func RestartButtonPressed() -> void :
    GameSaveManager.DeleteLevelProgress(TowerDefenseManager.currentControl.levelConfig.name)
    DialogCreate("ReStart")

func MainMenuButtonPressed() -> void :
    if !Global.isMultiplayerMode:
        GameSaveManager.SaveLevelProgress(TowerDefenseManager.currentControl.levelConfig.name)
    match Global.enterLevelMode:
        "OnlineLevel":
            InternetServerManager.OnlineLevelPost(Global.enterLevelId, "abandon")
    SceneManager.ChangeScene("MainMenu")

func LevelEditorButtonPressed() -> void :
    if !Global.isMultiplayerMode:
        GameSaveManager.SaveLevelProgress(TowerDefenseManager.currentControl.levelConfig.name)
    match Global.enterLevelMode:
        "OnlineLevel":
            InternetServerManager.OnlineLevelPost(Global.enterLevelId, "abandon")
    SceneManager.ChangeScene("LevelEditorStage")
