extends Node

const CHECK_INIT = preload("res://Asset/Config/Check/CheckInit.json")

const TOWER_DEFENSE_PACKET_INIT: JSON = preload("res://Asset/Config/Save/TowerDefensePacketInit.json")
const FEATURE_INIT: JSON = preload("res://Asset/Config/Save/FeatureInit.json")
const TUTORIAL_INIT: JSON = preload("res://Asset/Config/Save/TutorialInit.json")
const LEVEL_INIT: JSON = preload("res://Asset/Config/Save/LevelInit.json")
const KEY_INIT = preload("res://Asset/Config/Save/KeyInit.json")

const CONFIG_INIT = preload("res://Asset/Config/Save/ConfigInit.json")

const PATH: String = "user://save.res"
const PATHCONFIG: String = "user://config.res"
const PATHDAILYLEVEL: String = "user://DailyLevel"
const PATHONLINELEVEL: String = "user://OnlineLevel"

const pathDebug: String = "res://Core/Save/save.res"
const pathConfigDebug: String = "res://Core/Save/config.res"
const pathDailyLevelDebug: String = "res://Core/Save/DailyLevel"
const pathOnlineLevelDebug: String = "res://Core/Save/OnlineLevel"

@export var config: GameSaveConfig
@export var gameConfig: GameConfigSaveConfig

var saveScheduled: bool = false
var configDirty: bool = false

var savePath: String:
    get: return pathDebug if Global.debug else PATH
var configPath: String:
    get: return pathConfigDebug if Global.debug else PATHCONFIG
var dailyLevelPath: String:
    get: return pathDailyLevelDebug if Global.debug else PATHDAILYLEVEL
var onlineLevelPath: String:
    get: return pathOnlineLevelDebug if Global.debug else PATHONLINELEVEL

func _ready() -> void :
    set_process(false)
    if !DirAccess.dir_exists_absolute(dailyLevelPath):
        DirAccess.make_dir_recursive_absolute(dailyLevelPath)
    if !DirAccess.dir_exists_absolute(onlineLevelPath):
        DirAccess.make_dir_recursive_absolute(onlineLevelPath)
    if !FileAccess.file_exists(configPath):
        gameConfig = GameConfigSaveConfig.new()
    else:
        var resLoad = ResourceLoader.load(configPath)
        if resLoad is GameConfigSaveConfig:
            gameConfig = resLoad
        else:
            gameConfig = GameConfigSaveConfig.new()

    if Global.isMobile:
        if GetConfigValue("FullScreen"):
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

    Global.animeFrameRate = GetConfigValue("AnimeFrameRate")

func _process(_delta: float) -> void :
    if configDirty:
        configDirty = false
        ResourceSaver.save(gameConfig, configPath)
    if !configDirty:
        set_process(false)

func Check() -> void :
    for checkData: Dictionary in CHECK_INIT.data:
        var data: bool = CheckCondition(checkData["CheckType"], checkData["CheckKey"])
        if data:
            ApplySave(checkData["SaveType"], checkData["SaveKey"])

func CheckCondition(type: String, key: String) -> bool:
    match type:
        "Packet":
            return GetTowerDefensePacketValue(key)["Unlock"]
        "Feature":
            return GetFeatureValue(key)
        "Tutorial":
            return GetTutorialValue(key)
        "Level":
            return GetLevelValue(key)["Key"]["Finish"] > 0
        "Key":
            return GetKeyValue(key)
        "Config":
            return GetConfigValue(key)
    return false

func ApplySave(type: String, key: String) -> void :
    match type:
        "Packet":
            var saveData = GetTowerDefensePacketValue(key)
            if !saveData["Unlock"]:
                saveData["Unlock"] = true
            SetTowerDefensePacketValue(key, saveData)
        "Feature":
            SetFeatureValue(key, true)
        "Tutorial":
            SetTutorialValue(key, true)
        "Level":
            var saveData = GetLevelValue(key)
            if saveData["Key"]["Finish"] <= 0:
                saveData["Key"]["Finish"] += 1
            SetLevelValue(key, saveData)
        "Key":
            SetKeyValue(key, true)
        "Config":
            SetConfigValue(key, true)

func Save() -> void :
    if GetUserCurrent() != "":
        Check()
    SetKeyValue("CoinNum", TowerDefenseManager.coinBank.num)
    if !config:
        Load()
    ResourceSaver.save(config, savePath)
    SaveGameConfig()

func SaveGameConfig() -> void :
    ResourceSaver.save(gameConfig, configPath)

func ScheduleSave() -> void :
    if !saveScheduled:
        saveScheduled = true
        call_deferred("DeferredSave")

func DeferredSave() -> void :
    saveScheduled = false
    Save()

func Load() -> void :
    if !FileAccess.file_exists(savePath):
        config = GameSaveConfig.new()
        Save()
    else:
        var resLoad = ResourceLoader.load(savePath)
        if resLoad is GameSaveConfig:
            config = resLoad
        else:
            config = GameSaveConfig.new()
        if config.userCurrent != "":
            TowerDefenseManager.coinBank.num = GetKeyValue("CoinNum")
            if GetKeyValue("CrystalNum") < 0:
                RefreshCrystalNum()
    if GetUserCurrent() != "":
        Check()

func EnsureUser() -> String:
    var user: String = GetUserCurrent()


    return user

func GetUserCurrent() -> String:
    if config:
        return config.userCurrent
    return ""

func SetUserCurrent(user: String) -> void :
    if !config.userList.has(user):
        AddUser(user)
        Save()
    config.userCurrent = user
    TowerDefenseManager.coinBank.num = GetKeyValue("CoinNum")
    if GetKeyValue("CrystalNum") < 0:
        RefreshCrystalNum()
    Save()

func GetUserList() -> Array[String]:
    return config.userList

func HasUser(user: String) -> bool:
    return config.userList.has(user)

func AddUser(user: String) -> void :
    if !HasUser(user):
        config.InitUser(user)
    Save()

func RenameUser(user: String, newName: String) -> void :
    if HasUser(user):
        config.RenameUser(user, newName)

func DeleteUser(user: String) -> void :
    if HasUser(user):
        config.DeleteUser(user)
        if config.userList.size() > 0:
            SetUserCurrent(config.userList[0])
        else:
            SetUserCurrent("")
    Save()

func GetUserDictionary(user: String) -> Dictionary:
    if !config.userList.has(user):
        return {}
    return config.saveDictionary[user]

func GetCategoryDictionary(category: String) -> Dictionary:
    var userCurrent: String = GetUserCurrent()
    if userCurrent == "":
        return {}
    if !config.saveDictionary[userCurrent].has(category):
        config.call(category + "DictionaryInit", config.saveDictionary[userCurrent])
    return config.saveDictionary[userCurrent][category]

func GetCategoryValue(category: String, key: String, initData: Dictionary) -> Variant:
    if EnsureUser() == "":
        return false
    var catDict: Dictionary = GetCategoryDictionary(category)
    if !catDict.has(key):
        catDict[key] = initData[key]
    return catDict[key]

func SetCategoryValue(category: String, key: String, value: Variant, initData: Dictionary) -> void :
    if EnsureUser() == "":
        return
    var catDict: Dictionary = GetCategoryDictionary(category)
    if !catDict.has(key):
        catDict[key] = initData[key]
    catDict[key] = value

func GetTowerDefensePacketDictionary() -> Dictionary:
    return GetCategoryDictionary("TowerDefensePacket")

func GetTowerDefensePacketValue(key: String) -> Dictionary:
    if EnsureUser() == "":
        return {}
    var packetDictionary: Dictionary = GetTowerDefensePacketDictionary()
    if !packetDictionary.has(key):
        packetDictionary[key] = config.TowerDefensePacketDictionaryInitData(TOWER_DEFENSE_PACKET_INIT.data[key])
    return packetDictionary[key]

func SetTowerDefensePacketValue(key: String, value: Dictionary) -> void :
    if EnsureUser() == "":
        return
    var packetDictionary: Dictionary = GetTowerDefensePacketDictionary()
    if !packetDictionary.has(key):
        packetDictionary[key] = config.TowerDefensePacketDictionaryInitData(TOWER_DEFENSE_PACKET_INIT.data[key])
    packetDictionary[key] = value

func GetFeatureDictionary() -> Dictionary:
    return GetCategoryDictionary("Feature")

func GetFeatureValue(key: String) -> int:
    return GetCategoryValue("Feature", key, FEATURE_INIT.data)

func SetFeatureValue(key: String, value: Variant) -> void :
    SetCategoryValue("Feature", key, value, FEATURE_INIT.data)

func GetTutorialDictionary() -> Dictionary:
    return GetCategoryDictionary("Tutorial")

func GetTutorialValue(key: String) -> bool:
    return GetCategoryValue("Tutorial", key, TUTORIAL_INIT.data)

func SetTutorialValue(key: String, value: bool) -> void :
    SetCategoryValue("Tutorial", key, value, TUTORIAL_INIT.data)

func GetLevelDictionary() -> Dictionary:
    return GetCategoryDictionary("Level")

func GetLevelValue(key: String) -> Dictionary:
    if EnsureUser() == "" || key == "":
        return {}
    var levelDictionary: Dictionary = GetLevelDictionary()
    if !levelDictionary.has(key):
        if LEVEL_INIT.data.has(key):
            levelDictionary[key] = LEVEL_INIT.data[key]
        else:
            levelDictionary[key] = {}
    return levelDictionary[key]

func SetLevelValue(key: String, value: Dictionary) -> void :
    if EnsureUser() == "":
        return
    var levelDictionary: Dictionary = GetLevelDictionary()
    if !levelDictionary.has(key):
        if LEVEL_INIT.data.has(key):
            levelDictionary[key] = LEVEL_INIT.data[key]
        else:
            levelDictionary[key] = {}
    levelDictionary[key] = value

func GetKeyDictionary() -> Dictionary:
    return GetCategoryDictionary("Key")

func GetKeyValue(key: String) -> Variant:
    return GetCategoryValue("Key", key, KEY_INIT.data)

func SetKeyValue(key: String, value: Variant) -> void :
    SetCategoryValue("Key", key, value, KEY_INIT.data)

func GetConfigDictionary() -> Dictionary:
    if gameConfig.saveDictionary.is_empty():
        gameConfig.Init()
    return gameConfig.saveDictionary

func GetConfigValue(key: String) -> Variant:
    if !gameConfig.saveDictionary.has(key):
        gameConfig.saveDictionary[key] = CONFIG_INIT.data[key]
    return gameConfig.saveDictionary[key]

func SetConfigValue(key: String, value: Variant) -> void :
    if !gameConfig.saveDictionary.has(key):
        gameConfig.saveDictionary[key] = CONFIG_INIT.data[key]
    gameConfig.saveDictionary[key] = value
    if !configDirty:
        configDirty = true
        set_process(true)

func GetDailyLevel(levelName: String) -> JSON:
    var path: String = dailyLevelPath + "/" + levelName + ".json"
    if FileAccess.file_exists(path):
        var json: JSON = load(path)
        if json.data:
            return json
    return null

func SaveDailyLevel(levelName: String, json: JSON) -> void :
    var path: String = dailyLevelPath + "/" + levelName + ".json"
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(json.get_parsed_text())
    file.close()

func GetOnlineLevel(levelName: String) -> JSON:
    var path: String = onlineLevelPath + "/" + levelName + ".json"
    if FileAccess.file_exists(path):
        var json: JSON = load(path)
        if json.data:
            return json
    return null

func SaveOnlineLevel(levelName: String, json: JSON) -> void :
    var path: String = onlineLevelPath + "/" + levelName + ".json"
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(json.get_parsed_text())
    file.close()

func SaveLevelProgress(levelName: String) -> void :
    if !is_instance_valid(TowerDefenseManager.currentControl) or !TowerDefenseManager.currentControl.isGameRunning:
        print("[Save] 游戏未在运行中，跳过保存")
        return
    var filePath: String = "user://Progress/%s/%s.tres" % [_GetUserCurrentSafe(), levelName]
    DirAccess.make_dir_recursive_absolute(filePath.get_base_dir())
    var saveConfig: TowerDefenseLevelSaveConfig = TowerDefenseLevelSaveConfig.new()
    saveConfig.Save()
    ResourceSaver.save(saveConfig, filePath)

func LoadLevelProgress(levelName: String) -> void :
    var saveConfig: TowerDefenseLevelSaveConfig = GetLevelProgress(levelName)
    if saveConfig:
        saveConfig.Load()

func GetLevelProgress(levelName: String) -> TowerDefenseLevelSaveConfig:
    var filePath: String = "user://Progress/%s/%s.tres" % [_GetUserCurrentSafe(), levelName]
    if !FileAccess.file_exists(filePath):
        return null
    return ResourceLoader.load(filePath, "", ResourceLoader.CACHE_MODE_IGNORE)

func DeleteLevelProgress(levelName: String) -> void :
    var filePath: String = "user://Progress/%s/%s.tres" % [_GetUserCurrentSafe(), levelName]
    DirAccess.remove_absolute(filePath)

func HasLevelProgress(levelName: String) -> bool:
    var filePath: String = "user://Progress/%s/%s.tres" % [_GetUserCurrentSafe(), levelName]
    return FileAccess.file_exists(filePath)

func _GetUserCurrentSafe() -> String:
    return GetUserCurrent().validate_filename()

func RefreshCrystalNum() -> void :
    var levelDictionary = GetLevelDictionary()
    var finishNum: int = 0
    for key: String in levelDictionary.keys():
        if !key.begins_with("OnlineLevel"):
            continue
        if levelDictionary[key].get("Key", {}).get("Finish", 0) <= 0:
            continue
        finishNum += 1
    SetKeyValue("CrystalNum", finishNum)
    GameSaveManager.Save()
