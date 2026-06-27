extends Node2D

@onready var versionHttpRequest: HTTPRequest = %VersionHTTPRequest
@onready var dailyLevelHTTPRequest: HTTPRequest = %DailyLevelHTTPRequest
@onready var onlineLevelHTTPRequest: HTTPRequest = %OnlineLevelHTTPRequest
@onready var onlineLevelPostHTTPRequest: HTTPRequest = %OnlineLevelPostHTTPRequest
@onready var exportFileHTTPRequest: HTTPRequest = %ExportFileHTTPRequest
@onready var loadFileHTTPRequest: HTTPRequest = %LoadFileHTTPRequest

signal onlineLevelGet(data: Dictionary)

signal share_level_success(code: String, expireAt: int, expireSeconds: int)
signal share_level_failed(message: String)
signal get_shared_level_success(data: PackedByteArray)
signal get_shared_level_failed(message: String)

signal daily_level_month_loaded(year: int, month: int)

var versionGetOver: bool = false
var newVersion: String = ""

var dailyLevelGetOver: bool = false
var dailyLevelLoadedMonths: Dictionary = {}
var dailyLevelRequestYear: int = 0
var dailyLevelRequestMonth: int = 0

func _ready() -> void :
    versionHttpRequest.request("https://api.pvzhe.com/new_version", Global.header)

@warning_ignore("unused_parameter")
func VersionHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        print("版本检查失败: %s" % Global.GetHTTPRequestErrorMessage(result))
        return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    if json.data:
        versionGetOver = true
        var response = json.get_data()
        var platform: String = "pc"
        if Global.isMobile:
            platform = "android"
        var getVersion: Array = response[platform].get("version", [-1, -1, -1, -1])
        var base64: String = response[platform].get("base64", "error")
        Global.uri = response[platform].get("url", "error")
        var stringList: PackedStringArray = []
        for number in getVersion:
            stringList.append(str(int(number)))
        newVersion = ".".join(stringList)
        prints("newVersion:", newVersion)
        prints("uri:", Global.uri)
        prints("base64:", base64)
        if base64 != "error":
            var checkString = Marshalls.base64_to_utf8(base64)
            print("checkString:", checkString)
            if checkString == newVersion + Global.uri:
                Global.newVersion = newVersion
                var flag: bool = false
                var vesionSplit = Global.version.split(".")

                for ind in getVersion.size():
                    if vesionSplit[ind].to_int() < int(getVersion[ind]):
                        flag = true
                        break
                    elif vesionSplit[ind].to_int() > int(getVersion[ind]):
                        break

                Global.hasNewVersion = flag
                if !Global.hasNewVersion:
                    GetDailyLevel()

func GetDailyLevel(year: int = 0, month: int = 0) -> void :
    if year == 0 || month == 0:
        var datetime = Time.get_datetime_dict_from_system()
        year = datetime.year
        month = datetime.month
    var monthKey: String = "%d-%02d" % [year, month]
    if dailyLevelLoadedMonths.has(monthKey):
        daily_level_month_loaded.emit(year, month)
        return
    dailyLevelRequestYear = year
    dailyLevelRequestMonth = month
    dailyLevelHTTPRequest.cancel_request()
    dailyLevelHTTPRequest.request("https://api.pvzhe.com/get_daily_levels?year=%d&month=%d" % [year, month], Global.header)

@warning_ignore("unused_parameter")
func DailyLevelHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        print("每日关卡获取失败: %s" % Global.GetHTTPRequestErrorMessage(result))
        return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    if json.data:
        var responseData: Dictionary = json.get_data()
        if ResourceManager.DAILY_LEVEL_DATA.is_empty():
            ResourceManager.DAILY_LEVEL_DATA = responseData
        else:
            if responseData.has("LevelDateMap"):
                for key in responseData["LevelDateMap"]:
                    ResourceManager.DAILY_LEVEL_DATA["LevelDateMap"][key] = responseData["LevelDateMap"][key]
            if responseData.has("LevelMeta"):
                for key in responseData["LevelMeta"]:
                    ResourceManager.DAILY_LEVEL_DATA["LevelMeta"][key] = responseData["LevelMeta"][key]
        var monthKey: String = "%d-%02d" % [dailyLevelRequestYear, dailyLevelRequestMonth]
        dailyLevelLoadedMonths[monthKey] = true
        dailyLevelGetOver = true
        daily_level_month_loaded.emit(dailyLevelRequestYear, dailyLevelRequestMonth)

func GetOnlineLevelPage(pageIndex: int = 1, suffix: String = "", suffix2: String = "", search: String = "") -> void :
    pageIndex = clamp(pageIndex, 1, 100000)
    onlineLevelHTTPRequest.cancel_request()
    if search != "":
        onlineLevelHTTPRequest.request("https://api.pvzhe.com/workshop/levels?page=%d%s%s&search=%s" % [pageIndex, suffix, suffix2, search.uri_encode()], Global.header)
    else:
        onlineLevelHTTPRequest.request("https://api.pvzhe.com/workshop/levels?page=%d%s%s" % [pageIndex, suffix, suffix2], Global.header)

@warning_ignore("unused_parameter")
func OnlineLevelHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        onlineLevelGet.emit({})
        return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    if json.data:
        onlineLevelGet.emit(json.data)

func OnlineLevelPost(levelId: String, suffix: String = "abandon") -> void :
    onlineLevelPostHTTPRequest.request("https://api.pvzhe.com/workshop/levels/%s/%s" % [levelId, suffix], Global.header, HTTPClient.METHOD_POST)

@warning_ignore("unused_parameter")
func OnlineLevelPostHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8())



func ShareFile(data: PackedByteArray) -> void :
    exportFileHTTPRequest.cancel_request()
    var headers = Global.header.duplicate()
    headers.append("Content-Type: application/octet-stream")
    exportFileHTTPRequest.request_raw("https://api.pvzhe.com/save_share", headers, HTTPClient.METHOD_POST, data.compress(FileAccess.CompressionMode.COMPRESSION_GZIP))

func ShareLevel(data: PackedByteArray) -> void :
    exportFileHTTPRequest.cancel_request()
    var headers = Global.header.duplicate()
    headers.append("Content-Type: application/octet-stream")
    exportFileHTTPRequest.request_raw("https://api.pvzhe.com/save_share", headers, HTTPClient.METHOD_POST, data)

func GetSharedFile(code: String) -> void :
    loadFileHTTPRequest.cancel_request()
    loadFileHTTPRequest.request("https://api.pvzhe.com/save_share?code=%s" % code, Global.header)


@warning_ignore("unused_parameter")
func ExportFileHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        share_level_failed.emit(Global.GetHTTPRequestErrorMessage(result))
        return
    if response_code == 200:
        var json = JSON.new()
        json.parse(body.get_string_from_utf8())
        if json.data:
            var response = json.get_data()
            var code = response.get("code", "")
            var expireAt = response.get("expireAt", 0)
            var expireSeconds = response.get("expireSeconds", 0)
            share_level_success.emit(code, expireAt, expireSeconds)
        else:
            share_level_failed.emit("解析响应失败")
    else:
        var json = JSON.new()
        json.parse(body.get_string_from_utf8())
        if json.data:
            var message = json.get_data().get("message", "未知错误")
            share_level_failed.emit(message)
        else:
            share_level_failed.emit("请求失败，状态码: %d" % response_code)

@warning_ignore("unused_parameter")
func LoadFileHTTPRequestCompleted(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
    if result != HTTPRequest.RESULT_SUCCESS:
        get_shared_level_failed.emit(Global.GetHTTPRequestErrorMessage(result))
        return
    if response_code == 200:
        get_shared_level_success.emit(body)
    else:
        var json = JSON.new()
        json.parse(body.get_string_from_utf8())
        if json.data:
            var message = json.get_data().get("message", "未知错误")
            get_shared_level_failed.emit(message)
        else:
            get_shared_level_failed.emit("请求失败，状态码: %d" % response_code)
