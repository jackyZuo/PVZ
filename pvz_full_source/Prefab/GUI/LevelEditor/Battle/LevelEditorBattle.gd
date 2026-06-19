class_name LevelEditorBattle extends Control

const LEVEL_EDITOR_ONLINE_LEVEL_ITEM = preload("uid://7tkumqfm20gv")

const ARENA_REWARD_001 = preload("uid://c6wk0iut0oxr2")
const ARENA_REWARD_002 = preload("uid://camqjpt2tnw07")
const ARENA_REWARD_003 = preload("uid://g0nshu8rrw67")
const ARENA_REWARD_004 = preload("uid://oe6bi12ymuwh")
const ARENA_REWARD_005 = preload("uid://ctlmif5y5srn")
@onready var failCheckBox: Array[CheckBox] = [ %FailCheckBox, %FailCheckBox2, %FailCheckBox3]

@onready var mainNode: Control = %MainNode
@onready var tipsNode: Control = %TipsNode
@onready var awardNode: Control = %AwardNode
@onready var overNode: Control = %OverNode
@onready var historyNode: Control = %HistoryNode

@onready var levelGetHTTPRequest: HTTPRequest = %LevelGetHTTPRequest
@onready var levelDataGetHTTPRequest: HTTPRequest = %LevelDataGetHTTPRequest
@onready var levelListGetHTTPRequest: HTTPRequest = %LevelListGetHTTPRequest

@onready var levelEditorOnlineLevelItem: Control = %LevelEditorOnlineLevelItem
@onready var finishLabel: Label = %FinishLabel
@onready var ticketLabel: Label = %TicketLabel
@onready var awardLabel: Label = %AwardLabel

@onready var rewardButton: SpriteBrightButton = %RewardButton
@onready var costomRewardTexture1: Sprite2D = %CostomRewardTexture1
@onready var costomRewardTexture2: Sprite2D = %CostomRewardTexture2

@onready var historyDragMenu: DragMenu = %HistoryDragMenu
@onready var historyNooneLabel: Label = %HistoryNooneLabel

static var levelList: Array = []

var currentLevelId: String = ""
var currentLevelData: Dictionary
var failNum: int = 0
var finishNum: int = 0

const coinNumList: Array = [500, 1000, 2000, 3000, 5000, 8000, 12000, 16000, 20000, 30000, 40000, 50000, 80000]
const awardString: Array = [
    "奖励500金币", 
    "奖励1000金币", 
    "奖励2000金币", 
    "奖励3000金币", 
    "奖励5000金币", 
    "奖励8000金币", 
    "奖励12000金币", 
    "奖励16000金币", 
    "奖励20000金币", 
    "奖励30000金币", 
    "奖励40000金币+随机皮肤*1", 
    "奖励50000金币+随机皮肤*1", 
    "奖励80000金币+随机皮肤*2", 
]

func Show() -> void :
    await get_tree().physics_frame


    currentLevelId = GameSaveManager.GetKeyValue("LevelEditorBattleCurrentLevel")
    failNum = GameSaveManager.GetKeyValue("LevelEditorBattleFailNum")
    finishNum = GameSaveManager.GetKeyValue("LevelEditorBattleFinishNum")
    FreshFinish(finishNum)
    FreshFail(failNum)
    if currentLevelId == "-1":
        RandomLevel()
    else:
        levelDataGetHTTPRequest.request("https://api.pvzhe.com/workshop/levels?include_id=%s" % currentLevelId, Global.header)

func RandomLevel() -> void :








    levelDataGetHTTPRequest.request("https://api.pvzhe.com/workshop/levels/ids?feature=comp&random=1", Global.header)

func FreshFail(num: int) -> void :
    match num:
        0:
            failCheckBox[0].button_pressed = false
            failCheckBox[1].button_pressed = false
            failCheckBox[2].button_pressed = false
        1:
            failCheckBox[0].button_pressed = true
            failCheckBox[1].button_pressed = false
            failCheckBox[2].button_pressed = false
        2:
            failCheckBox[0].button_pressed = true
            failCheckBox[1].button_pressed = true
            failCheckBox[2].button_pressed = false
        3:
            failCheckBox[0].button_pressed = true
            failCheckBox[1].button_pressed = true
            failCheckBox[2].button_pressed = true
            Over(true)

func FreshFinish(num: int) -> void :
    finishLabel.text = "胜场:%d" % num

    costomRewardTexture1.visible = false
    costomRewardTexture2.visible = false
    match num:
        0, 1, 2:
            rewardButton.texture = ARENA_REWARD_001
        3, 4, 5:
            rewardButton.texture = ARENA_REWARD_002
        6, 7, 8:
            rewardButton.texture = ARENA_REWARD_003
        9:
            rewardButton.texture = ARENA_REWARD_004
        10, 11:
            rewardButton.texture = ARENA_REWARD_004
            costomRewardTexture1.visible = true
        12:
            rewardButton.texture = ARENA_REWARD_005
            costomRewardTexture1.visible = true
            costomRewardTexture2.visible = true
        _:
            var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
            tipsDialog.text = "[center][font_size=24]数据错误[/font_size][/center]"
    match num:
        0:
            awardLabel.text = "奖池：%d金币" % 500
        1:
            awardLabel.text = "奖池：%d金币" % 1000
        2:
            awardLabel.text = "奖池：%d金币" % 2000
        3:
            awardLabel.text = "奖池：%d金币" % 3000
        4:
            awardLabel.text = "奖池：%d金币" % 5000
        5:
            awardLabel.text = "奖池：%d金币" % 8000
        6:
            awardLabel.text = "奖池：%d金币" % 12000
        7:
            awardLabel.text = "奖池：%d金币" % 16000
        8:
            awardLabel.text = "奖池：%d金币" % 20000
        9:
            awardLabel.text = "奖池：%d金币" % 30000
        10:
            awardLabel.text = "奖池：%d金币+随机皮肤*1" % 40000
        11:
            awardLabel.text = "奖池：%d金币+随机皮肤*1" % 50000
        12:
            awardLabel.text = "奖池：%d金币+随机皮肤*2" % 80000
            Over(false)
        _:
            var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
            tipsDialog.text = "[center][font_size=24]数据错误[/font_size][/center]"

func EnterLevel(url: String, id: String) -> void :
    currentLevelId = id
    if url != "":
        var fileUrl: String = "https://api.pvzhe.com%s" % url
        levelGetHTTPRequest.request(fileUrl, Global.header)

@warning_ignore("unused_parameter")
func LevelListGetHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        BroadCastManager.BroadCastFloatCreate(Global.GetHTTPRequestErrorMessage(result), Color.RED)
        return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8(), true)
    if json.data:
        levelList = json.data
        if currentLevelId == "-1":
            if !levelList.is_empty():
                RandomLevel()

@warning_ignore("unused_parameter")
func LevelDataGetHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        BroadCastManager.BroadCastFloatCreate(Global.GetHTTPRequestErrorMessage(result), Color.RED)
        return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8(), true)
    if json.data:
        if typeof(json.data) == TYPE_DICTIONARY:
            if json.data.has("list") && json.data["list"].size() > 0:
                currentLevelData = json.data["list"][0]
                levelEditorOnlineLevelItem.Init(currentLevelData)
            else:
                RandomLevel()
        if typeof(json.data) == TYPE_ARRAY:
            var id = str(int(json.data[0]))
            var _levelName: String = "OnlineLevel-%s" % id
            var _levelData: Dictionary = GameSaveManager.GetLevelValue(_levelName)
            if _levelData.get_or_add("Key", {}).get_or_add("Finish", 0) <= 0:
                currentLevelId = str(id)
                GameSaveManager.SetKeyValue("LevelEditorBattleCurrentLevel", currentLevelId)
                levelDataGetHTTPRequest.request("https://api.pvzhe.com/workshop/levels?include_id=%s" % currentLevelId, Global.header)

@warning_ignore("unused_parameter")
func LevelGetHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        BroadCastManager.BroadCastFloatCreate(Global.GetHTTPRequestErrorMessage(result), Color.RED)
        return
    @warning_ignore("unused_variable")
    var levelName: String = "OnlineLevel-%s" % currentLevelId
    var json = JSON.new()
    json.parse(body.get_string_from_utf8(), true)
    if json.data:
        if json.data.has("error"):
            if json.data["error"]:
                BroadCastManager.BroadCastFloatCreate("关卡Id无效", Color.RED)
                return
        json.data["Name"] = levelName
        json.data["Reward"] = {}
        json.data["Reward"]["RewardType"] = "Coin"
        json.data["Reward"]["RewardFirst"] = "1000"
        var saveJson = JSON.new()
        saveJson.parse(JSON.stringify(json.data), true)
        GameSaveManager.SaveOnlineLevel(levelName, saveJson)
        ToBattle(saveJson)

func ToBattle(json: JSON) -> void :
    var historyData: Dictionary = GameSaveManager.GetKeyValue("OnlinehBattleHistory")
    var historyList: Array = historyData.get_or_add("Level", []) as Array
    if historyList.size() > 20:
        historyList.pop_back()
    historyList.push_front(
        {
            "id": currentLevelData.get("id", ""), 
            "name": currentLevelData.get("name", ""), 
            "map": currentLevelData.get("map", "")
        }
    )
    GameSaveManager.SetKeyValue("OnlinehBattleHistory", historyData)
    GameSaveManager.Save()

    TowerDefenseManager.UseCoin(500)
    var config: TowerDefenseLevelConfig = TowerDefenseLevelConfig.new()
    config.data = json
    config.Init()
    TowerDefenseManager.currentLevelConfig = config
    Global.enterLevelMode = "OnlineLevel"
    Global.enterLevelIsBattle = true
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        MultiPlayerManager.selectedLevelId = ""
        MultiPlayerManager.SendLevelConfig()
        MultiPlayerManager.ResetLevelConfigAck()
        if !MultiPlayerManager.CheckAllLevelConfigAcked():
            await MultiPlayerManager.all_level_config_acked
        MultiPlayerManager.SendStartGame()
        return
    SceneManager.ChangeScene("TowerDefense")

func RefreshButtonPressed() -> void :
    if TowerDefenseManager.GetCoin() < 1000:
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]您的金币数量不足1000\n无法刷新关卡[/font_size][/center]"
    else:
        var chooseDialog = DialogManager.DialogCreate("DialogBoxChoose")
        chooseDialog.text = "[center][font_size=24]刷新关卡[/font_size][/center]\n[center][font_size=16]是否花费1000金币刷新关卡？[/font_size][/center]"
        chooseDialog.chooseTrue.connect(
            func():
                RandomLevel()
                TowerDefenseManager.UseCoin(1000)
        )

func TipsButtonPressed() -> void :
    TowerDefenseManager.coinBank.Hide.call_deferred()
    mainNode.visible = false
    tipsNode.visible = true

func RewardButtonPressed() -> void :
    TowerDefenseManager.coinBank.Hide.call_deferred()
    mainNode.visible = false
    awardNode.visible = true

func Over(fail: bool) -> void :
    overNode.visible = true
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(rewardButton, ^"global_position", Vector2(410, 204), 1.0)
    await tween.finished

    var methodString: String = ""
    var costomString: String = ""
    var coinNum: int = coinNumList[finishNum]
    if fail:
        methodString = "失败到达上限"
    else:
        methodString = "闯关成功"

    match finishNum:
        10:
            var data = RandomCustom()
            costomString += "\n" + data.get("String", "")
            coinNum += data.get("Coin", 0)
        11:
            var data = RandomCustom()
            costomString += "\n" + data.get("String", "")
            coinNum += data.get("Coin", 0)
        12:
            var data = RandomCustom()
            costomString += "\n" + data.get("String", "")
            coinNum += data.get("Coin", 0)
            data = RandomCustom()
            costomString += "\n" + data.get("String", "")
            coinNum += data.get("Coin", 0)
    var broadCastConfig: BroadCastConfig = BroadCastConfig.new()
    broadCastConfig.broadCastString = "%s，您一共完成%d个关卡\n%s%s" % [methodString, finishNum, awardString[finishNum], costomString]
    BroadCastManager.BroadCastAdd(broadCastConfig)

    await CreateCoin(coinNum)
    await get_tree().create_timer(2.0, false).timeout

    BroadCastManager.BraodCastClear()


    tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(rewardButton, ^"global_position", Vector2(470, 320), 1.0)
    await tween.finished

    overNode.visible = false

    GameSaveManager.SetKeyValue("LevelEditorBattleFailNum", 0)
    GameSaveManager.SetKeyValue("LevelEditorBattleFinishNum", 0)

    failNum = GameSaveManager.GetKeyValue("LevelEditorBattleFailNum")
    finishNum = GameSaveManager.GetKeyValue("LevelEditorBattleFinishNum")

    FreshFinish(finishNum)
    FreshFail(failNum)
    GameSaveManager.Save()

func RandomCustom() -> Dictionary:
    var characterName: String = ""
    var customConfig: CharacterCustomConfig = null
    while (true):
        var packetName = ResourceManager.GetPacketNames().pick_random()
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
        var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
        if is_instance_valid(characterConfig.customData):
            if characterConfig.customData.customList.size() > 0:
                characterName = tr(packetConfig.name)
                customConfig = characterConfig.customData.customList.pick_random()
                break
    if is_instance_valid(customConfig):
        var open = customConfig.openKey == "" || GameSaveManager.GetFeatureValue(customConfig.openKey)
        if open:
            var coinNum: int = 10000
            if customConfig.type == "Gold":
                coinNum = 20000
            return {
                "String": "你已获得%s的皮肤:%s,为你转化为%d金币" % [characterName, tr(customConfig.customHandbookName), coinNum], 
                "Coin": coinNum
            }
        else:
            GameSaveManager.SetFeatureValue(customConfig.openKey, true)
            return {
                "String": "恭喜你获得%s的皮肤:%s" % [characterName, tr(customConfig.customHandbookName)], 
                "Coin": 0
            }
    return {}

func CreateCoin(num) -> void :
    while num >= 1000:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_DIAMOND, rewardButton.global_position + Vector2(50, 40), 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos.y = 200
        item.reparent(self, false)
        get_tree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        get_tree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 1000
        await get_tree().create_timer(0.1, false).timeout
    while num >= 50:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, rewardButton.global_position + Vector2(50, 40), 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos.y = 200
        item.reparent(self, false)
        get_tree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        get_tree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 50
        await get_tree().create_timer(0.1, false).timeout
    while num >= 10:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, rewardButton.global_position + Vector2(50, 40), 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos.y = 200
        item.reparent(self, false)
        get_tree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        get_tree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 10
        await get_tree().create_timer(0.1, false).timeout

func HistoryButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    historyNode.visible = true
    historyNooneLabel.visible = false
    var historyData: Dictionary = GameSaveManager.GetKeyValue("OnlinehBattleHistory")
    var historyList: Array = historyData.get_or_add("Level", []) as Array

    for node in historyDragMenu.get_children():
        node.queue_free()

    for levelData in historyList:
        var item = LEVEL_EDITOR_ONLINE_LEVEL_ITEM.instantiate()
        historyDragMenu.add_child(item)
        item.pivot_offset = item.size / 2.0
        item.Init(levelData)

    if historyList.size() <= 0:
        historyNooneLabel.visible = true
