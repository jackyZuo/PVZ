extends DialogBoxBase
@onready var layer: CanvasLayer = %Layer

@onready var levelInformationGetHTTPRequest: HTTPRequest = %LevelInformationGetHTTPRequest
@onready var levelLikeSendHTTPRequest: HTTPRequest = %LevelLikeSendHTTPRequest

@onready var nameLabel: Label = %NameLabel
@onready var mapTexture: TextureRect = %MapTexture
@onready var playButton: MainButton = %PlayButton
@onready var closeButton: TextureButton = %CloseButton

@onready var authorLabel: RichTextLabel = %AuthorLabel
@onready var describeLabel: RichTextLabel = %DescribeLabel
@onready var levelIdLabel: RichTextLabel = %LevelIDLabel
@onready var playedNumLabel: RichTextLabel = %PlayedNumLabel
@onready var dateLabel: RichTextLabel = %DateLabel

@onready var collectionButton: TextureButton = %CollectionButton

@onready var likeButton: TextureButton = %LikeButton
@onready var dislikeButton: TextureButton = %DislikeButton

@onready var likeLabel: RichTextLabel = %LikeLabel
@onready var dislikeLabel: RichTextLabel = %DislikeLabel

signal select(url: String)

var levelData: Dictionary = {}
var id: String = ""
var levelName: String = ""
var map: String = ""
var author: String = ""
var description: String = ""
var fileUrl: String = ""
var playedNum: int = 0
var date: int = 0
var likeNum: int = 0
var dislikeNum: int = 0
var loadOver: bool = false

func InitDialog(_id: String) -> void :
    id = _id
    var url: String = "https://api.pvzhe.com/workshop/levels/%s" % _id
    levelInformationGetHTTPRequest.request(url, Global.header)

func InitDialogData(_levelData: Dictionary) -> void :
    levelData = _levelData
    id = levelData.get("id", "")
    levelName = levelData.get("name", "")
    map = levelData.get("map", "")
    author = levelData.get("author", "")
    description = levelData.get("description", "")
    fileUrl = levelData.get("fileUrl", "")
    playedNum = levelData.get("plays", "")
    date = levelData.get("uploadTime", "")
    likeNum = levelData.get("likes", 0)
    dislikeNum = levelData.get("dislikes", 0)
    nameLabel.text = levelName
    var mapConfig: TowerDefenseMapConfig = TowerDefenseManager.GetMapConfig(map)
    mapTexture.texture = mapConfig.mapTexture

    authorLabel.text = "作者:%s" % author
    describeLabel.text = "简介:%s" % description
    levelIdLabel.text = "关卡ID:%s" % id
    playedNumLabel.text = "游玩次数:%d" % playedNum
    dateLabel.text = "上传日期:%s" % Time.get_datetime_string_from_unix_time(date + Time.get_time_zone_from_system().bias * 60, true)

    var myCollectionData: Dictionary = GameSaveManager.GetKeyValue("OnlineMyCollection")
    var myCollectionList: Array = myCollectionData.get("Level", [])
    for data: Dictionary in myCollectionList:
        var colectionLevelId: String = data.get("id", "-1")
        if colectionLevelId == id:
            collectionButton.button_pressed = true
            break
    collectionButton.disabled = false
    collectionButton.toggled.connect(CollectionButtonToggled)
    loadOver = true

    var _levelName: String = "OnlineLevel-%s" % id
    var _levelInformationData: Dictionary = GameSaveManager.GetLevelValue(_levelName)
    var likeValue = _levelInformationData.get_or_add("Key", {}).get_or_add("Like", -1)
    if likeValue != -1:
        likeButton.disabled = false
        dislikeButton.disabled = false
        if likeValue == 0:
            dislikeButton.button_pressed = true
        else:
            likeButton.button_pressed = true
        likeLabel.text = "赞\n%d" % likeNum
        dislikeLabel.text = "踩\n%d" % dislikeNum
        likeButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dislikeButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
    else:
        likeButton.disabled = false
        dislikeButton.disabled = false

    if id.begins_with("-"):
        collectionButton.visible = false
        likeButton.visible = false
        dislikeButton.visible = false

func CloseButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    Close()

func PlayButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    if loadOver:
        Global.enterLevelId = id
        select.emit(fileUrl)
        playButton.disabled = true
        closeButton.disabled = true
    else:
        BroadCastManager.BroadCastFloatCreate("关卡正在加载中...", Color.RED)

@warning_ignore("unused_parameter")
func LevelInformationGetHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        BroadCastManager.BroadCastFloatCreate(Global.GetHTTPRequestErrorMessage(result), Color.RED)
        Close()
        return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8(), true)
    if json.data.get("id", "-1") != "-1":
        InitDialogData(json.data)
    else:
        BroadCastManager.BroadCastFloatCreate("关卡不存在或者被删除", Color.RED)
        Close()

func CollectionButtonToggled(toggledOn: bool) -> void :
    var myCollectionData: Dictionary = GameSaveManager.GetKeyValue("OnlineMyCollection")
    var myCollectionList: Array = myCollectionData.get_or_add("Level", []) as Array
    if toggledOn:
        myCollectionList.append(
            {
                "id": id, 
                "name": levelName, 
                "map": map
            }
        )
    else:
        for index in myCollectionList.size():
            var data: Dictionary = myCollectionList[index]
            if data.get("id", "-1") == id:
                myCollectionList.remove_at(index)
                break
    myCollectionData["Level"] = myCollectionList
    GameSaveManager.SetKeyValue("OnlineMyCollection", myCollectionData)
    GameSaveManager.Save()

@warning_ignore("unused_parameter")
func LikeButtonPressed() -> void :
    var _levelName: String = "OnlineLevel-%s" % id
    var _levelData: Dictionary = GameSaveManager.GetLevelValue(_levelName)
    if _levelData.get_or_add("Key", {}).get_or_add("Play", 0) > 0 || _levelData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0:
        _levelData.get_or_add("Key", {}).get_or_add("Like", -1)
        _levelData["Key"]["Like"] = 1
        GameSaveManager.SetLevelValue(_levelName, _levelData)
        GameSaveManager.Save()
        levelLikeSendHTTPRequest.request("https://api.pvzhe.com/workshop/levels/%s/like" % id, Global.header, HTTPClient.METHOD_POST)
        likeButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dislikeButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
        likeNum += 1
        likeLabel.text = "赞\n%d" % likeNum
        dislikeLabel.text = "踩\n%d" % dislikeNum
        likeButton.button_pressed = true
        CreateCoin(likeButton.global_position, 100)
    else:
        var tipsDialog = DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]至少游玩一次才能评价[/font_size][/center]"
        likeButton.button_pressed = false

@warning_ignore("unused_parameter")
func DislikeButtonPressed() -> void :
    var _levelName: String = "OnlineLevel-%s" % id
    var _levelData: Dictionary = GameSaveManager.GetLevelValue(_levelName)
    if _levelData.get_or_add("Key", {}).get_or_add("Play", 0) > 0 || _levelData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0:
        _levelData.get_or_add("Key", {}).get_or_add("Like", -1)
        _levelData["Key"]["Like"] = 0
        GameSaveManager.SetLevelValue(_levelName, _levelData)
        GameSaveManager.Save()
        levelLikeSendHTTPRequest.request("https://api.pvzhe.com/workshop/levels/%s/dislike" % id, Global.header, HTTPClient.METHOD_POST)
        likeButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dislikeButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dislikeNum += 1
        likeLabel.text = "赞\n%d" % likeNum
        dislikeLabel.text = "踩\n%d" % dislikeNum
        dislikeButton.button_pressed = true
        CreateCoin(dislikeButton.global_position, 100)
    else:
        var tipsDialog = DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]至少游玩一次才能评价[/font_size][/center]"
        dislikeButton.button_pressed = false


func CreateCoin(pos: Vector2, num: int) -> void :
    while num >= 1000:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_DIAMOND, pos, 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos.y = 200
        item.reparent(collectionButton)
        get_tree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        get_tree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 1000
        await get_tree().create_timer(0.1, false).timeout
    while num >= 50:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, pos, 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos.y = 200
        item.reparent(collectionButton)
        get_tree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        get_tree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 50
        await get_tree().create_timer(0.1, false).timeout
    while num >= 10:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, pos, 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos.y = 200
        item.reparent(collectionButton)
        get_tree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        get_tree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 10
        await get_tree().create_timer(0.1, false).timeout
