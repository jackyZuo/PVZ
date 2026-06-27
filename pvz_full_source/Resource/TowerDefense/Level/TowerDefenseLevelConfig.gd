@tool
class_name TowerDefenseLevelConfig extends TowerDefenseLevelBaseConfig

@export_storage var canExport: bool = false:
    set(_canExport):
        canExport = _canExport

@export var data: JSON:
    set(_data):
        data = _data
        Init()

@export var featureData: Dictionary[StringName, Dictionary]
@export var processName: StringName
@export var processData: Dictionary

@export var finishMethod: TowerDefenseEnum.LEVEL_FINISH_METHOD = TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE
@export var baseTimeScale: float = 1.0
@export_category("Mower")
@export var mowerUse: bool = true
@export_category("Tutorial")
@export var talk: Variant = ""
@export var tutorial: Variant = ""
@export_category("Map")
@export var map: String = "Frontlawn"
@export_category("BGM")
@export var backgroundMusic: String = "Frontlawn"
@export_category("Reward")
@export var firstRewardType: TowerDefenseEnum.LEVEL_REWARDTYPE = TowerDefenseEnum.LEVEL_REWARDTYPE.COIN
@export_storage var firstRewardValue = 2000
@export_category("Event")
@export var eventInit: Array[TowerDefenseLevelEventBase] = []
@export var eventReady: Array[TowerDefenseLevelEventBase] = []
@export var eventStart: Array[TowerDefenseLevelEventBase] = []
@export_category("PreSpawn")
@export var preSpawnList: Array[TowerDefenseLevelPreSpawnConfig] = []
@export_category("PacketBank")
@export var limitGridPlantNum: int = -1
@export var plantColumn: bool = false
@export var packetColdDownStart: bool = true
@export var packetColdDownUse: bool = true
@export var packetBankMethod: TowerDefenseEnum.LEVEL_SEEDBANK_METHOD = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
    set(_packetBankMethod):
        packetBankMethod = _packetBankMethod
        notify_property_list_changed()
@export_category("Effect")
@export var stormOpen: bool = false
@export_category("Sun")
@export var sunManager: TowerDefenseLevelSunManagerConfig = TowerDefenseLevelSunManagerConfig.new()
@export_category("Fog")
@export var fogManager: TowerDefenseLevelFogManagerConfig = TowerDefenseLevelFogManagerConfig.new()
@export_category("LookStar")
@export var lookStarManager: TowerDefenseLevelLookStarManagerConfig = TowerDefenseLevelLookStarManagerConfig.new()
@export_category("Wave")
@export var waveManager: TowerDefenseLevelWaveManagerConfig
@export_category("Vase")
@export var vaseManager: TowerDefenseLevelVaseManagerConfig
@export_category("Vase")
@export var _IZMManager: TowerDefenseLevelIZMManagerConfig
@export_category("Option")
@export var isCustomTalk: bool = false
@export var isCustomTutorial: bool = false
@export var customTalk: NpcTalkConfig
@export var customTutorial: TutorialConfig

@export_storage var packetBank: String = "GeneralPlant"
@export var packetBankList: Array = []
@export var conveyorData: TowerDefenseConveyorConfig
@export var rainData: TowerDefenseRainModeConfig

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    match packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
            properties.append(
                {
                    "name": "PacketBank/Name", 
                    "type": TYPE_STRING, 
                }
            )
    return properties

func _set(property: StringName, value: Variant) -> bool:
    match property:
        "PacketBank/Name":
            packetBank = value
            return true
    return false

func _get(property: StringName) -> Variant:
    match property:
        "PacketBank/Name":
            return packetBank
    return null

func _property_can_revert(property: StringName) -> bool:
    match property:
        "PacketBank/Name":
            return true
    return false

func _property_get_revert(property: StringName) -> Variant:
    match property:
        "PacketBank/Name":
            return ""
    return null

func Clear() -> void :
    homeWorld = GeneralEnum.HOMEWORLD.NOONE
    finishMethod = TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE
    packetBankMethod = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE
    eventInit.clear()
    eventReady.clear()
    eventStart.clear()
    sunManager = null
    fogManager = null
    lookStarManager = null
    waveManager = null
    vaseManager = null
    _IZMManager = null
    isCustomTalk = false
    isCustomTutorial = false
    customTalk = null
    customTutorial = null
    packetBankList.clear()
    conveyorData = null
    rainData = null
    featureData.clear()
    processName = &""
    processData = {}

func Init() -> void :
    if !data:
        ExportToFeatureProcess()
        return
    Clear()

    var levelData: Dictionary = data.data as Dictionary
    name = levelData.get("Name", "")
    levelName = levelData.get("LevelName", "")
    description = levelData.get("Description", "")
    levelNumber = levelData.get("LevelNumber", 0)
    nextLevel = levelData.get("NextLevel", "")
    homeWorld = GeneralEnum.HOMEWORLD.get(levelData.get("HomeWorld", "NOONE").to_upper())
    finishMethod = TowerDefenseEnum.LEVEL_FINISH_METHOD.get(levelData.get("FinishMethod", "WAVE").to_upper())
    baseTimeScale = levelData.get("BaseTimeScale", 1.0)

    mowerUse = levelData.get("MowerUse", true)

    var talkGet = levelData.get("Talk", "")
    if talkGet is Dictionary:
        isCustomTalk = true
        customTalk = NpcTalkConfig.new()
        customTalk.Load(talkGet)
    else:
        isCustomTalk = false
        talk = talkGet

    var tutorialGet = levelData.get("Tutorial", "")
    if tutorialGet is Dictionary:
        isCustomTutorial = true
        customTutorial = TutorialConfig.new()
        customTutorial.Load(tutorialGet)
    else:
        isCustomTutorial = false
        tutorial = tutorialGet

    map = levelData.get("Map", "")

    backgroundMusic = levelData.get("BGM", "")

    stormOpen = levelData.get("StormOpen", false)

    var rewardData: Dictionary = levelData.get("Reward", {}) as Dictionary
    firstRewardType = TowerDefenseEnum.LEVEL_REWARDTYPE.get(str(rewardData.get("RewardType", "NOONE")).to_upper())
    firstRewardValue = rewardData.get("RewardFirst")

    var eventData: Dictionary = levelData.get("Event", {}) as Dictionary
    var eventInitList: Array = eventData.get("EventInit", []) as Array
    for eventInitDictionary: Dictionary in eventInitList:
        var eventName: String = eventInitDictionary.get("EventName", "")
        if eventName:
            var event = TowerDefenseLevelEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventInitDictionary.get("Value", {})
            event.Init(eventValue)
            eventInit.append(event)

    var eventReadyList: Array = eventData.get("EventReady", []) as Array
    for eventReadyDictionary: Dictionary in eventReadyList:
        var eventName: String = eventReadyDictionary.get("EventName", "")
        if eventName:
            var event = TowerDefenseLevelEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventReadyDictionary.get("Value", {})
            event.Init(eventValue)
            eventReady.append(event)

    var eventStartist: Array = eventData.get("EventStart", []) as Array
    for eventStartDictionary: Dictionary in eventStartist:
        var eventName: String = eventStartDictionary.get("EventName", "")
        if eventName:
            var event = TowerDefenseLevelEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventStartDictionary.get("Value", {})
            event.Init(eventValue)
            eventStart.append(event)

    preSpawnList = []
    var preSpawnData: Dictionary = levelData.get("PreSpawn", {}) as Dictionary
    var packetList: Array = preSpawnData.get("Packet", []) as Array
    for packetData in packetList:
        if is_instance_valid(packetData) || packetData == null:
            continue
        var preSpawnConfig: TowerDefenseLevelPreSpawnConfig = TowerDefenseLevelPreSpawnConfig.new()
        preSpawnConfig.Init(packetData)
        preSpawnList.append(preSpawnConfig)

    var packetBankData: Dictionary = levelData.get("PacketBank", {}) as Dictionary
    limitGridPlantNum = packetBankData.get("LimitGridPlantNum", -1)
    packetColdDownStart = packetBankData.get("ColdDownStart", true)
    packetColdDownUse = packetBankData.get("ColdDownUse", true)
    packetBankMethod = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.get(packetBankData.get("Method", "NOONE").to_upper())
    plantColumn = packetBankData.get("PlantColumn", false)
    var packetBankValue = packetBankData.get("Value", [])

    match packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
            for packetData in packetBankValue:
                var packet: TowerDefenseLevelPacketConfig = TowerDefenseLevelPacketConfig.new()
                packet.Init(packetData)
                packetBankList.append(packet)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
            for packetData in packetBankValue:
                var packet: TowerDefenseLevelPacketConfig = TowerDefenseLevelPacketConfig.new()
                packet.Init(packetData)
                packetBankList.append(packet)
            packetBank = packetBankData.get("Type", "")
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
            conveyorData = TowerDefenseConveyorConfig.new()
            if packetBankValue.size() == 1 && (typeof(packetBankValue[0]) == TYPE_DICTIONARY && packetBankValue[0].has("Packet")):
                conveyorData.Init(packetBankValue[0])
            else:
                conveyorData.Init(packetBankData.get("ConveyorPreset", []))
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
            rainData = TowerDefenseRainModeConfig.new()
            if packetBankValue.size() == 1 && (typeof(packetBankValue[0]) == TYPE_DICTIONARY && packetBankValue[0].has("Packet")):
                rainData.Init(packetBankValue[0])
            else:
                rainData.Init(packetBankData.get("RainPreset", []))

    var sunManagerData: Dictionary = levelData.get("SunManager", {}) as Dictionary
    sunManager = TowerDefenseLevelSunManagerConfig.new()
    sunManager.Init(sunManagerData)

    var fogManagerData: Dictionary = levelData.get("FogManager", {}) as Dictionary
    fogManager = TowerDefenseLevelFogManagerConfig.new()
    fogManager.Init(fogManagerData)

    var lookStarManagerData: Dictionary = levelData.get("LookStarManager", {}) as Dictionary
    lookStarManager = TowerDefenseLevelLookStarManagerConfig.new()
    lookStarManager.Init(lookStarManagerData)

    match finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE, TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
            var waveManagerData: Dictionary = levelData.get("WaveManager", {}) as Dictionary
            waveManager = TowerDefenseLevelWaveManagerConfig.new()
            waveManager.Init(waveManagerData)
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            var vaseManagerData: Dictionary = levelData.get("VaseManager", {}) as Dictionary
            vaseManager = TowerDefenseLevelVaseManagerConfig.new()
            vaseManager.Init(vaseManagerData)
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            var _IZMManagerData: Dictionary = levelData.get("IZMManager", {}) as Dictionary
            _IZMManager = TowerDefenseLevelIZMManagerConfig.new()
            _IZMManager.Init(_IZMManagerData)

    featureData.clear()
    var featureArray: Array = levelData.get("Feature", [])
    for feature: Dictionary in featureArray:
        var featureName: StringName = feature.get("Name", "")
        var featureDict: Dictionary = feature.get("Data", {})
        featureData[featureName] = featureDict

    var processDict: Dictionary = levelData.get("Process", {})
    if !processDict.is_empty():
        processName = processDict.get("Name", "")
        processData = processDict.get("Data", {})

    if featureData.is_empty():
        featureData["Camera"] = {}
        featureData["Map"] = {"MapName": map}
        featureData["Shovel"] = {}
        featureData["PacketPick"] = {}
        featureData["Mower"] = {}
        featureData["Brain"] = {}
        featureData["Progess"] = {}
        var preSpawnFeatureData: Dictionary = levelData.get("PreSpawn", {})
        if !preSpawnFeatureData.is_empty():
            featureData["PreSpawn"] = preSpawnFeatureData
        if isCustomTalk && is_instance_valid(customTalk):
            var talkDict: Dictionary = (levelData.get("Talk", {}) as Dictionary).duplicate()
            talkDict["isCustom"] = true
            featureData["NpcTalk"] = talkDict
        elif talk != "":
            featureData["NpcTalk"] = {"TalkName": talk}
        var sunFeatureData: Dictionary = levelData.get("SunManager", {})
        if !sunFeatureData.is_empty():
            featureData["Sun"] = sunFeatureData
        if packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN && is_instance_valid(rainData):
            featureData["RainMode"] = rainData.Export()
        if packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR && is_instance_valid(conveyorData):
            featureData["ConveyorBelt"] = conveyorData.Export()
        if packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET || packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
            featureData["PacketBank"] = {"PacketBankName": packetBank}
            var seedBankData: Dictionary = {}
            seedBankData["Method"] = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.find_key(packetBankMethod)
            seedBankData["PlantColumn"] = plantColumn
            seedBankData["ColdDownStart"] = packetColdDownStart
            seedBankData["ColdDownUse"] = packetColdDownUse
            seedBankData["Packet"] = []
            for packetItem in packetBankList:
                if packetItem is TowerDefenseLevelPacketConfig:
                    seedBankData["Packet"].append(packetItem.Export())
                elif typeof(packetItem) == TYPE_STRING:
                    seedBankData["Packet"].append(packetItem)
            featureData["SeedBank"] = seedBankData
        featureData["BGM"] = {"BackgroundMusic": backgroundMusic}
        var fogFeatureData: Dictionary = levelData.get("FogManager", {})
        if !fogFeatureData.is_empty():
            if fogFeatureData["Open"]:
                featureData["Fog"] = fogFeatureData
        var lookStarFeatureData: Dictionary = levelData.get("LookStarManager", {})
        if !lookStarFeatureData.is_empty():
            if lookStarFeatureData["Open"]:
                featureData["LookStar"] = lookStarFeatureData
        featureData["ScreenEffect"] = {"StormOpen": stormOpen, "PacketBankMethod": packetBankMethod}
        if isCustomTutorial && is_instance_valid(customTutorial):
            var tutorialDict: Dictionary = (levelData.get("Tutorial", {}) as Dictionary).duplicate()
            tutorialDict["isCustom"] = true
            featureData["Tutorial"] = tutorialDict
        elif tutorial != "":
            featureData["Tutorial"] = {"TutorialName": tutorial}
        var eventFeatureData: Dictionary = levelData.get("Event", {})
        if !eventFeatureData.is_empty():
            featureData["Event"] = eventFeatureData
        if finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE || finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
            featureData["Wave"] = levelData.get("WaveManager", {})

    if processName == &"":
        match finishMethod:
            TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
                processName = "Wave"
                processData = levelData.get("WaveManager", {}).duplicate()
                processData["StormOpen"] = stormOpen
                processData["MowerUse"] = mowerUse
            TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
                processName = "IZM2"
                processData = levelData.get("WaveManager", {}).duplicate()
                processData["StormOpen"] = stormOpen
                processData["MowerUse"] = mowerUse
            TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
                processName = "Vase"
                processData = levelData.get("VaseManager", {}).duplicate()
            TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
                processName = "IZM"
                processData = levelData.get("IZMManager", {}).duplicate()
            TowerDefenseEnum.LEVEL_FINISH_METHOD.QUIZ:
                processName = "Quiz"

func Export() -> Dictionary:
    var _data: Dictionary = {
        "LevelName": levelName, 
        "LevelNumber": levelNumber, 
        "Description": description, 
        "HomeWorld": GeneralEnum.HOMEWORLD.find_key(homeWorld), 
        "FinishMethod": TowerDefenseEnum.LEVEL_FINISH_METHOD.find_key(finishMethod), 
        "Talk": talk, 
        "Tutorial": tutorial, 
        "Map": map, 
        "BGM": backgroundMusic, 
        "MowerUse": mowerUse, 
        "StormOpen": stormOpen, 
        "Reward": {
            "RewardType": TowerDefenseEnum.LEVEL_REWARDTYPE.find_key(firstRewardType), 
            "RewardFirst": firstRewardValue
        }, 
        "Event": {
            "EventInit": [], 
            "EventReady": [], 
            "EventStart": [], 
        }, 
        "PreSpawn": {
            "Packet": []
        }, 
        "PacketBank": {
            "LimitGridPlantNum": limitGridPlantNum, 
            "PlantColumn": plantColumn, 
            "ColdDownUse": packetColdDownUse, 
            "ColdDownStart": packetColdDownStart, 
            "Method": TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.find_key(packetBankMethod), 
            "Type": packetBank, 
            "Value": []
        }, 
        "SunManager": sunManager.Export(), 
        "FogManager": fogManager.Export(), 
        "LookStarManager": lookStarManager.Export()
    }
    for preSpawn: TowerDefenseLevelPreSpawnConfig in preSpawnList:
        _data["PreSpawn"]["Packet"].append(preSpawn.Export())

    for eventGet: TowerDefenseLevelEventBase in eventInit:
        _data["Event"]["EventInit"].append(eventGet.Export())
    for eventGet: TowerDefenseLevelEventBase in eventReady:
        _data["Event"]["EventReady"].append(eventGet.Export())
    for eventGet: TowerDefenseLevelEventBase in eventStart:
        _data["Event"]["EventStart"].append(eventGet.Export())

    for packetData in packetBankList:
        if packetData is TowerDefenseLevelPacketConfig:
            _data["PacketBank"]["Value"].append(packetData.Export())
        elif typeof(packetData) == TYPE_STRING:
            _data["PacketBank"]["Value"].append(packetData)
    match packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
            _data["PacketBank"]["ConveyorPreset"] = conveyorData.Export()
            _data["PacketBank"]["Value"] = []
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
            _data["PacketBank"]["RainPreset"] = rainData.Export()
            _data["PacketBank"]["Value"] = []

    match finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
            _data["WaveManager"] = waveManager.Export()
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            _data["VaseManager"] = vaseManager.Export()
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            _data["IZMManager"] = _IZMManager.Export()

    return _data

func ExportToFeatureProcess() -> void :
    featureData.clear()
    featureData["Camera"] = {}
    featureData["Map"] = {"MapName": map}
    featureData["Shovel"] = {}
    featureData["PacketPick"] = {}
    featureData["Mower"] = {}
    featureData["Brain"] = {}
    featureData["Progess"] = {}
    if !preSpawnList.is_empty():
        var preSpawnFeatureData: Dictionary = {"Packet": []}
        for preSpawn: TowerDefenseLevelPreSpawnConfig in preSpawnList:
            preSpawnFeatureData["Packet"].append(preSpawn.Export())
        featureData["PreSpawn"] = preSpawnFeatureData
    if isCustomTalk && is_instance_valid(customTalk):
        if is_instance_valid(customTalk.data) && customTalk.data.data is Dictionary:
            var talkDict: Dictionary = (customTalk.data.data as Dictionary).duplicate()
            talkDict["isCustom"] = true
            featureData["NpcTalk"] = talkDict
    elif talk != "":
        featureData["NpcTalk"] = {"TalkName": talk}
    if is_instance_valid(sunManager):
        featureData["Sun"] = sunManager.Export()
    if packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN && is_instance_valid(rainData):
        featureData["RainMode"] = rainData.Export()
    if packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR && is_instance_valid(conveyorData):
        featureData["ConveyorBelt"] = conveyorData.Export()
    if packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET || packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
        featureData["PacketBank"] = {"PacketBankName": packetBank}
        var seedBankData: Dictionary = {}
        seedBankData["Method"] = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.find_key(packetBankMethod)
        seedBankData["PlantColumn"] = plantColumn
        seedBankData["ColdDownStart"] = packetColdDownStart
        seedBankData["ColdDownUse"] = packetColdDownUse
        seedBankData["Packet"] = []
        for packetItem in packetBankList:
            if packetItem is TowerDefenseLevelPacketConfig:
                seedBankData["Packet"].append(packetItem.Export())
            elif typeof(packetItem) == TYPE_STRING:
                seedBankData["Packet"].append(packetItem)
        featureData["SeedBank"] = seedBankData
    featureData["BGM"] = {"BackgroundMusic": backgroundMusic}
    if is_instance_valid(fogManager) && fogManager.open:
        featureData["Fog"] = fogManager.Export()
    if is_instance_valid(lookStarManager) && lookStarManager.open:
        featureData["LookStar"] = lookStarManager.Export()
    featureData["ScreenEffect"] = {"StormOpen": stormOpen, "PacketBankMethod": packetBankMethod}
    if isCustomTutorial && is_instance_valid(customTutorial):
        if is_instance_valid(customTutorial.data) && customTutorial.data.data is Dictionary:
            var tutorialDict: Dictionary = (customTutorial.data.data as Dictionary).duplicate()
            tutorialDict["isCustom"] = true
            featureData["Tutorial"] = tutorialDict
    elif tutorial != "":
        featureData["Tutorial"] = {"TutorialName": tutorial}
    var eventFeatureData: Dictionary = {"EventInit": [], "EventReady": [], "EventStart": []}
    for eventGet: TowerDefenseLevelEventBase in eventInit:
        eventFeatureData["EventInit"].append(eventGet.Export())
    for eventGet: TowerDefenseLevelEventBase in eventReady:
        eventFeatureData["EventReady"].append(eventGet.Export())
    for eventGet: TowerDefenseLevelEventBase in eventStart:
        eventFeatureData["EventStart"].append(eventGet.Export())
    if !eventFeatureData["EventInit"].is_empty() || !eventFeatureData["EventReady"].is_empty() || !eventFeatureData["EventStart"].is_empty():
        featureData["Event"] = eventFeatureData
    if finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE || finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
        if is_instance_valid(waveManager):
            featureData["Wave"] = waveManager.Export()
    processName = &""
    processData = {}
    match finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
            processName = "Wave"
            if is_instance_valid(waveManager):
                processData = waveManager.Export()
            processData["StormOpen"] = stormOpen
            processData["MowerUse"] = mowerUse
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
            processName = "IZM2"
            if is_instance_valid(waveManager):
                processData = waveManager.Export()
            processData["StormOpen"] = stormOpen
            processData["MowerUse"] = mowerUse
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            processName = "Vase"
            if is_instance_valid(vaseManager):
                processData = vaseManager.Export()
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            processName = "IZM"
            if is_instance_valid(_IZMManager):
                processData = _IZMManager.Export()
        TowerDefenseEnum.LEVEL_FINISH_METHOD.QUIZ:
            processName = "Quiz"

func ConveyorPreset() -> void :
    packetBankMethod = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR
    waveManager.minNextWaveHealthPercentage = 0.45
    waveManager.maxNextWaveHealthPercentage = 0.35
    waveManager.beginCol = 9.0
    waveManager.spawnColEnd = 15.0
    waveManager.spawnColStart = 6.0
    sunManager.open = false

func RainPreset() -> void :
    packetBankMethod = TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN
    sunManager.open = false
