extends DialogPopup

@onready var restartButton = %RestartButton
@onready var backButton = %BackButton
@onready var backBattleButton: MainButton = %BackBattleButton

func _ready() -> void :
    if Global.enterLevelMode == "OnlineLevel":
        InternetServerManager.OnlineLevelPost(Global.enterLevelId, "failure")
        if Global.enterLevelIsBattle:
            Global.enterLevelIsBattleFinish = false
            backBattleButton.visible = true
            restartButton.visible = false
            backButton.visible = false
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        restartButton.visible = false
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        restartButton.visible = false
        backButton.visible = false
        backBattleButton.visible = false
        textLabel.clear()
        textLabel.append_text("[center]游戏结束\n等待房主操作...[/center]")
        MultiPlayerManager.match_left.connect(_on_host_left)

func _on_host_left() -> void :
    MultiPlayerManager.SendClientReady()
    SceneManager.ChangeScene("MainMenu")

func RestartButtonPressed() -> void :
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        MultiPlayerManager.SendMatchState(MatchOpCodes.GAME_RESULT, JSON.stringify({"leave": true}))
    SceneManager.ReloadScene()
    Close()

func BackButtonPressed() -> void :
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
            SceneManager.ChangeScene("LevelEditorStage")
    Close()

func BackBattleButtonPressed() -> void :
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        MultiPlayerManager.SendMatchState(MatchOpCodes.GAME_RESULT, JSON.stringify({"leave": true}))
    SceneManager.ChangeScene("LevelEditorStage")
    Close()
