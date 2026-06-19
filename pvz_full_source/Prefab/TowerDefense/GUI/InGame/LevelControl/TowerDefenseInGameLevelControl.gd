class_name TowerDefenseInGameLevelControl extends Control

@onready var worldEntryLabel: RichTextLabel = %WorldEntryLabel
@onready var survivleLabel: Label = %SurvivleLabel
@onready var tipsLabel: Label = %TipsLabel
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer

static var instance: TowerDefenseInGameLevelControl = null

var config: TowerDefenseLevelConfig

var awardPos: Vector2 = Vector2.ZERO
var awardCreate: bool = false

var hasSpawn: bool = false

func Init(_config: TowerDefenseLevelConfig) -> void :
    config = _config
    config.Init()
    var text = tr(config.description).replace("{UserName}", GameSaveManager.GetUserCurrent())
    worldEntryLabel.text = text

func _ready() -> void :
    instance = self
    worldEntryLabel.visible = false

func ReadySetPlantPlay() -> void :
    AudioManager.AudioPlay("ReadySetPlants", AudioManagerEnum.TYPE.SFX)
    if TowerDefenseManager.IsIZM2Mode():
        animationPlayer.play("ReadyPlaceZombies")
    else:
        animationPlayer.play("ReadySetPlants")
    await get_tree().create_timer(2.0, false).timeout

func TipsPlay(text: String, duration: float = 2.0) -> void :
    tipsLabel.visible = true
    tipsLabel.text = text
    animationPlayer.play("Tips")
    await get_tree().create_timer(duration, false).timeout
    tipsLabel.visible = false

func AwardCreate(pos: Vector2) -> void :
    if awardCreate:
        return
    awardCreate = true
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        MultiPlayerManager.SendGameResult(true)
    if (Global.isEditor && Global.enterLevelMode == "DiyLevel") || Global.enterLevelMode == "LoadLevel" || Global.enterLevelMode == "OnlineLevel":
        if Global.enterLevelMode == "OnlineLevel":
            InternetServerManager.OnlineLevelPost(Global.enterLevelId, "completion")
            var _levelData: Dictionary = GameSaveManager.GetLevelValue(config.name)
            var _finishNum = _levelData.get_or_add("Key", {}).get_or_add("Finish", 0)
            _levelData["Key"]["Finish"] = _finishNum + 1
            GameSaveManager.SetKeyValue("CrystalNum", GameSaveManager.GetKeyValue("CrystalNum") + 1)
            GameSaveManager.SetLevelValue(config.name, _levelData)
            GameSaveManager.Save()
            if Global.enterLevelIsBattle:
                Global.enterLevelIsBattleFinish = true
        if Global.enterLevelMode == "DiyLevel":
            TowerDefenseManager.currentLevelConfig.canExport = true
        if (Global.isEditor && Global.enterLevelMode == "DiyLevel"):
            var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
            tipsDialog.text = "[center][font_size=24]您已完成关卡[/font_size][/center]"
            await tipsDialog.tree_exited
            get_tree().paused = false
            Global.timeScale = 1.0
            SceneManager.ChangeScene("LevelEditorStage")
            return

        TowerDefenseManager.CreateAward(TowerDefenseEnum.LEVEL_REWARDTYPE.TROPHY, "250", pos)
        return
    if config.talk != "":
        var talkFile: NpcTalkConfig = TowerDefenseManager.GetNpcTalk(config.talk)
        GameSaveManager.SetTutorialValue(talkFile.saveKey, true)
    if config.tutorial != "":
        var tutorial: TutorialConfig = TowerDefenseManager.GetTutorial(config.tutorial)
        GameSaveManager.SetTutorialValue(tutorial.saveKey, true)
    var firstAward: bool = false
    var difficult: String = GameSaveManager.GetKeyValue("CurrentDifficult")
    var levelData: Dictionary = GameSaveManager.GetLevelValue(config.name)
    var finishNum = levelData.get_or_add("Key", {}).get_or_add("Finish", 0)
    levelData["Key"]["Finish"] = finishNum + 1
    var mowerFeature: TowerDefenseBattleFeatureMower = TowerDefenseManager.GetMowerFeature()
    if (mowerFeature && !mowerFeature.mowerHasRun) || TowerDefenseManager.IsIZM2Mode():
        levelData["Mower"] = true
    var difficultValue: bool = levelData.get_or_add(difficult, false)
    if !difficultValue:
        levelData[difficult] = true
    GameSaveManager.SetLevelValue(config.name, levelData)

    Global.currentAwardType = config.firstRewardType
    match config.firstRewardType:
        TowerDefenseEnum.LEVEL_REWARDTYPE.PACKET:
            if typeof(config.firstRewardValue) == TYPE_STRING:
                var packetData: Dictionary = GameSaveManager.GetTowerDefensePacketValue(config.firstRewardValue)
                if !packetData.get_or_add("Unlock", false):
                    packetData["Unlock"] = true
                    GameSaveManager.SetTowerDefensePacketValue(config.firstRewardValue, packetData)
                    Global.currentAwardValue = config.firstRewardValue
                    firstAward = true

            if typeof(config.firstRewardValue) == TYPE_ARRAY:
                for value in config.firstRewardValue:
                    var packetData: Dictionary = GameSaveManager.GetTowerDefensePacketValue(value)
                    if !packetData.get_or_add("Unlock", false):
                        packetData["Unlock"] = true
                        GameSaveManager.SetTowerDefensePacketValue(value, packetData)
                        if !firstAward:
                            Global.currentAwardValue = value
                            firstAward = true

        TowerDefenseEnum.LEVEL_REWARDTYPE.COLLECTABLE:
            if typeof(config.firstRewardValue) == TYPE_STRING:
                if !GameSaveManager.GetFeatureValue(config.firstRewardValue):
                    GameSaveManager.SetFeatureValue(config.firstRewardValue, true)
                    Global.currentAwardValue = config.firstRewardValue
                    firstAward = true

            if typeof(config.firstRewardValue) == TYPE_ARRAY:
                for value in config.firstRewardValue:
                    if !GameSaveManager.GetFeatureValue(value):
                        GameSaveManager.SetFeatureValue(value, true)
                        if !firstAward:
                            Global.currentAwardValue = value
                            firstAward = true

        TowerDefenseEnum.LEVEL_REWARDTYPE.COIN:
            if typeof(config.firstRewardValue) == TYPE_STRING:
                if levelData["Key"]["Finish"] == 1:
                    if !firstAward:
                        Global.currentAwardValue = config.firstRewardValue
                        firstAward = true

    if !firstAward:
        Global.currentAwardType = TowerDefenseEnum.LEVEL_REWARDTYPE.NOONE
        TowerDefenseManager.CreateAward(TowerDefenseEnum.LEVEL_REWARDTYPE.NOONE, "250", pos)
    else:
        TowerDefenseManager.CreateAward(config.firstRewardType, Global.currentAwardValue, pos)
    GameSaveManager.Save()
