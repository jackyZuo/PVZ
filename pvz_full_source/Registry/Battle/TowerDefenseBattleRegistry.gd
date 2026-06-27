class_name TowerDefenseBattleRegistry

static var isInit: bool = false
static var battleFeatureDictionary: Dictionary[StringName, TowerDefenseBattleFeature]
static var battleProcessDictionary: Dictionary[StringName, TowerDefenseBattleProcess]

static func Init() -> void :
    if isInit:
        return
    isInit = true
    RegisterInit()

static func RegisterInit() -> void :
    RegisterFeature("Camera", TowerDefenseBattleFeatureCamera.new())
    RegisterFeature("Map", TowerDefenseBattleFeatureMap.new())
    RegisterFeature("Shovel", TowerDefenseBattleFeatureShovel.new())
    RegisterFeature("Glove", TowerDefenseBattleFeatureGlove.new())
    RegisterFeature("PacketPick", TowerDefenseBattleFeaturePacketPick.new())
    RegisterFeature("Mower", TowerDefenseBattleFeatureMower.new())
    RegisterFeature("Brain", TowerDefenseBattleFeatureBrain.new())
    RegisterFeature("NpcTalk", TowerDefenseBattleFeatureNpcTalk.new())
    RegisterFeature("Sun", TowerDefenseBattleFeatureSun.new())
    RegisterFeature("Progess", TowerDefenseBattleFeatureProgess.new())
    RegisterFeature("RainMode", TowerDefenseBattleFeatureRainMode.new())
    RegisterFeature("ConveyorBelt", TowerDefenseBattleFeatureConveyorBelt.new())
    RegisterFeature("PacketBank", TowerDefenseBattleFeaturePacketBank.new())
    RegisterFeature("SeedBank", TowerDefenseBattleFeatureSeedBank.new())
    RegisterFeature("PreSpawn", TowerDefenseBattleFeaturePreSpawn.new())
    RegisterFeature("BGM", TowerDefenseBattleFeatureBGM.new())
    RegisterFeature("Fog", TowerDefenseBattleFeatureFog.new())
    RegisterFeature("LookStar", TowerDefenseBattleFeatureLookStar.new())
    RegisterFeature("ScreenEffect", TowerDefenseBattleFeatureScreenEffect.new())
    RegisterFeature("WarningLine", TowerDefenseBattleFeatureWarningLine.new())
    RegisterFeature("Portal", TowerDefenseBattleFeaturePortal.new())
    RegisterFeature("Tutorial", TowerDefenseBattleFeatureTutorial.new())
    RegisterFeature("Event", TowerDefenseBattleFeatureEvent.new())
    RegisterFeature("Hammer", TowerDefenseBattleFeatureHammer.new())
    RegisterFeature("GemMatch", TowerDefenseBattleFeatureGemMatch.new())
    RegisterFeature("Wave", TowerDefenseBattleFeatureWave.new())

    RegisterProcess("Wave", TowerDefenseBattleProcessWave.new())
    RegisterProcess("Vase", TowerDefenseBattleProcessVase.new())
    RegisterProcess("IZM", TowerDefenseBattleProcessIZM.new())
    RegisterProcess("IZM2", TowerDefenseBattleProcessIZM2.new())
    RegisterProcess("Quiz", TowerDefenseBattleProcessQuiz.new())
    RegisterProcess("Empty", TowerDefenseBattleProcessEmpty.new())
    RegisterDependence()

static func RegisterDependence() -> void :
    SetFeatureDependence("Camera", [], [])
    SetFeatureDependence("Map", [], [])
    SetFeatureDependence("Shovel", ["Map"], [])
    SetFeatureDependence("Glove", ["Map"], [])
    SetFeatureDependence("PacketPick", ["Map"], [])
    SetFeatureDependence("Mower", [], [])
    SetFeatureDependence("Brain", [], [])
    SetFeatureDependence("NpcTalk", ["BGM"], [])
    SetFeatureDependence("Sun", [], [])
    SetFeatureDependence("Progess", [], [])
    SetFeatureDependence("RainMode", [], [])
    SetFeatureDependence("ConveyorBelt", [], [])
    SetFeatureDependence("PacketBank", ["SeedBank"], [])
    SetFeatureDependence("SeedBank", [], [])
    SetFeatureDependence("PreSpawn", [], [])
    SetFeatureDependence("BGM", [], [])
    SetFeatureDependence("Fog", [], [])
    SetFeatureDependence("LookStar", [], [])
    SetFeatureDependence("ScreenEffect", [], [])
    SetFeatureDependence("WarningLine", [], [])
    SetFeatureDependence("Portal", [], [])
    SetFeatureDependence("Tutorial", [], [])
    SetFeatureDependence("Event", [], [])
    SetFeatureDependence("Hammer", [], [])
    SetFeatureDependence("GemMatch", ["Map", "Sun", "SeedBank"], [])
    SetFeatureDependence("Wave", ["Map", "Mower", "Sun", "Progess", "Camera", "SeedBank", "PacketBank", "LookStar"], [])
    SetProcessDependence("Wave", ["Map", "Mower", "Sun", "Progess", "Camera", "SeedBank", "PacketBank", "LookStar", "Wave"], [])
    SetProcessDependence("Vase", ["Map", "Mower"], [])
    SetProcessDependence("IZM", ["Map", "Brain"], [])
    SetProcessDependence("IZM2", ["Map", "Mower", "Sun", "Progess", "Camera", "SeedBank", "PacketBank", "LookStar", "Wave"], [])
    SetProcessDependence("Quiz", ["Map", "Brain"], [])
    SetProcessDependence("Empty", ["Map", "Camera"], [])



static func RegisterFeature(featureName: StringName, feature: TowerDefenseBattleFeature) -> void :
    battleFeatureDictionary[featureName] = feature

static func RegisterProcess(processName: StringName, process: TowerDefenseBattleProcess) -> void :
    battleProcessDictionary[processName] = process

static func SetFeatureDependence(featureName: StringName, _featureNames: Array[StringName], _processNames: Array[StringName]) -> void :
    if !battleFeatureDictionary.has(featureName):
        return
    var dependenceData: TowerDefenseBattleDependenceData = TowerDefenseBattleDependenceData.new()
    dependenceData.featureNames = _featureNames
    dependenceData.processNames = _processNames
    battleFeatureDictionary[featureName].dependenceData = dependenceData

static func SetProcessDependence(processName: StringName, _featureNames: Array[StringName], _processNames: Array[StringName]) -> void :
    if !battleProcessDictionary.has(processName):
        return
    var dependenceData: TowerDefenseBattleDependenceData = TowerDefenseBattleDependenceData.new()
    dependenceData.featureNames = _featureNames
    dependenceData.processNames = _processNames
    battleProcessDictionary[processName].dependenceData = dependenceData



static func GetFeature(featureName: StringName) -> TowerDefenseBattleFeature:
    if !battleFeatureDictionary.has(featureName):
        return null
    return battleFeatureDictionary[featureName].duplicate_deep()

static func GetProcess(processName: StringName) -> TowerDefenseBattleProcess:
    if !battleProcessDictionary.has(processName):
        return null
    return battleProcessDictionary[processName].duplicate_deep()

static func GetProcessByFinishMethod(finishMethod: TowerDefenseEnum.LEVEL_FINISH_METHOD) -> TowerDefenseBattleProcess:
    var processName: StringName = ""
    match finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
            processName = "Wave"
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            processName = "Vase"
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            processName = "IZM"
        TowerDefenseEnum.LEVEL_FINISH_METHOD.QUIZ:
            processName = "Quiz"
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
            processName = "IZM2"
        TowerDefenseEnum.LEVEL_FINISH_METHOD.EMPTY:
            processName = "Empty"
    return GetProcess(processName)
