@tool
extends Node

var version: String = "0.21.1.0"
var header: PackedStringArray = []
var isMobile: bool = false
signal animeFrameRateChange()

@export_tool_button("Fresh AllAnimeData") var freshAnimeData: Callable = FreshAnimeData
@export_tool_button("Fresh AllLevelData") var freshLevelData: Callable = FreshLevelData

@export var debug: bool = false
@export_group("Base")
@export var animeFrameRate: float = 30.0:
    set(_animeFrameRate):
        animeFrameRate = _animeFrameRate
        Engine.max_fps = int(animeFrameRate)
        if isMobile:
            Engine.physics_ticks_per_second = min(30, animeFrameRate)
        else:
            Engine.physics_ticks_per_second = min(45, animeFrameRate)
        animeFrameRateChange.emit()
@export var trueAnimeFrameRate: float:
    get():
        return animeFrameRate / timeScale

@export var timeScale: float = 1.0:
    set(_timeScale):
        timeScale = _timeScale
        Engine.time_scale = timeScale
        animeFrameRateChange.emit()

var enterLevelMode: String = "LevelChoose"
var enterLevelIsBattle: bool = false
var enterLevelIsBattleFinish: bool = false
var enterLevelId: String = "-1"
var enterTryLevelGroup: String = ""
var enterQuizMap: String = "Frontlawn"

var currentLevelChoose: String = "Adventure"
var currentChapterId: int = -1
var currentLevelId: int = -1
var currentAwardMode: bool = false
var currentAwardType: TowerDefenseEnum.LEVEL_REWARDTYPE = TowerDefenseEnum.LEVEL_REWARDTYPE.NOONE
var currentAwardValue: String = ""
var currentDiyLevelUid: String = ""

var isMultiplayerMode: bool = false
var isMultiplayerHost: bool = false

var newVersion: String = ""
var hasNewVersion: bool = false
var uri: String = ""
var newVersionSkip: bool = false

var maxFps: int = 60

var isEditor: bool = false

func GetHTTPRequestErrorMessage(result: int) -> String:
    match result:
        HTTPRequest.RESULT_SUCCESS:
            return ""
        HTTPRequest.RESULT_CANT_CONNECT:
            return "无法连接到服务器"
        HTTPRequest.RESULT_CANT_RESOLVE:
            return "无法解析服务器地址"
        HTTPRequest.RESULT_CONNECTION_ERROR:
            return "连接错误"
        HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
            return "TLS握手失败，请检查网络连接"
        HTTPRequest.RESULT_NO_RESPONSE:
            return "服务器无响应"
        HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
            return "响应数据过大"
        HTTPRequest.RESULT_REQUEST_FAILED:
            return "请求失败"
        HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
            return "无法打开下载文件"
        HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
            return "下载文件写入错误"
        HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
            return "重定向次数过多"
        _:
            return "未知网络错误(%d)" % result

func _ready() -> void :
    header.append("X-PVZHE-Client-Version:%s" % version)
    get_window().close_requested.connect(
        func():
            if Engine.is_editor_hint():
                return
            if is_instance_valid(TowerDefenseManager.currentControl) and !Global.isMultiplayerMode:
                GameSaveManager.SaveLevelProgress(TowerDefenseManager.currentControl.levelConfig.name)
            GameSaveManager.Save()
            CrashLogger._OnCleanQuit()
    )
    var osName: String = OS.get_name()
    isMobile = osName == "Android" || osName == "iOS"
    TranslationServer.set_locale("zh")
    maxFps = int(DisplayServer.screen_get_refresh_rate(DisplayServer.window_get_current_screen()))
    if isMobile:
        OS.request_permissions()


















func FreshAnimeData() -> void :
    var thread: Thread = Thread.new()
    thread.start(FreshAnimeDataOpenDir.bind("res://"))

func FreshAnimeDataOpenDir(path: String) -> void :
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                print("发现文件夹" + path + "//" + file_name)
                FreshAnimeDataOpenDir(path + "//" + file_name)
            else:
                print("发现文件" + path + "//" + file_name)
                if file_name.get_extension() == "tres":
                    var file = load(path + "//" + file_name)
                    if file is AdobeAnimateData:
                        file.Init()
                        ResourceSaver.save(file, path + "//" + file_name, ResourceSaver.FLAG_COMPRESS)
            file_name = dir.get_next()
    else:
        print("尝试访问路径时出错。")

func FreshLevelData() -> void :
    var thread: Thread = Thread.new()
    thread.start(FreshLevelDataOpenDir.bind("res://"))

func FreshLevelDataOpenDir(path: String) -> void :
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                print("发现文件夹" + path + "//" + file_name)
                FreshLevelDataOpenDir(path + "//" + file_name)
            else:
                print("发现文件" + path + "//" + file_name)
                if file_name.get_extension() == "tres":
                    var file = load(path + "//" + file_name)
                    if file is TowerDefenseLevelConfig:
                        file.Clear()
                        ResourceSaver.save(file)
            file_name = dir.get_next()
    else:
        print("尝试访问路径时出错。")
