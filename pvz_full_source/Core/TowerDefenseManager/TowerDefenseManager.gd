extends Node2D

const LEVEL_RESOURCE = preload("res://Asset/Config/Level/LevelResource.json")

const TOWER_DEFENSE_EFFECT_PARTICLES_ONCE: PackedScene = preload("uid://dbyd0mqkya1j3")
const TOWER_DEFENSE_EFFECT_SPRITE_ONCE: PackedScene = preload("uid://dwvgduivkprow")

const TOWER_DEFENSE_SUN = preload("uid://dk3bkihnh1i0l")
const TOWER_DEFENSE_BRAIN_SUN = preload("uid://d161xee5m0kkw")

const TOWER_DEFENSE_IN_GAME_PACKET_SHOW: PackedScene = preload("uid://bhqecss20rwpb")

const TOWER_DEFENSE_AWARD_PACKET = preload("uid://7l7qsvsxvioi")
const TOWER_DEFENSE_AWARD_PURSE = preload("uid://mux1v63kv0d8")
const TOWER_DEFENSE_AWARD_COLLECTABLE = preload("uid://d28midqtre16s")
const TOWER_DEFENSE_AWARD_TROPHY = preload("uid://dpoujenmcn5tb")

const ZOMBIE_DEATH_FALLING_OBJECT = preload("uid://ct867xau74s6u")

const TOWER_DEFENSE_ZOMBIE_BUNGI_SPAWN = preload("uid://bkp73arbrdgkt")

var eventBus: BattleEventBus
var characterRegistry: TowerDefenseBattleCharacterRegistry
var targetSystem: TargetSystem
var damagePipeline: DamagePipeline

@onready var coinBank: CoinBank = %CoinBank

var currentControl: TowerDefenseControlNew
@export var currentLevelConfig: TowerDefenseLevelConfig
var currentDynamicLevel: int = 3
var seedbankPacketMax: int = 7

var runGameTime: float = 0.0

var gridSize: Vector2
var gridBeginPos: Vector2
var gridNum: Vector2i

var pausePacket: bool = false
var pauseZombie: bool = false
var backPacket: bool = false
var backZombie: bool = false

static var deathList: Array[Dictionary] = []

static var luckyBagNum: int = 0

func CharacterRegister(character: TowerDefenseCharacter) -> void :
    characterRegistry.Register(character)

func CharacterUnregister(character: TowerDefenseCharacter) -> void :
    characterRegistry.Unregister(character)

func GetTowerDefenseServer() -> Node:
    if is_instance_valid(GlobalTowerDefenseServer):
        return GlobalTowerDefenseServer
    return null

func _GetCleanCharacters() -> Array[TowerDefenseCharacter]:
    return characterRegistry.GetCleanCharacters()

func _GetOverlappingAreasCached(checkArea: Area2D) -> Array:
    return characterRegistry.GetOverlappingAreasCached(checkArea)

func _ready() -> void :
    eventBus = BattleEventBus
    characterRegistry = TowerDefenseBattleCharacterRegistry.new()
    add_child(characterRegistry)
    targetSystem = TargetSystem.new(characterRegistry, self)
    add_child(targetSystem)
    damagePipeline = DamagePipeline.new()
    BattleEventBus.characterDestroy.connect(CharacterDestroy)

func MapIsChange() -> void :
    gridSize = GetMapGridSize()
    gridBeginPos = GetMapGridBeginPos()
    gridNum = GetMapGridNum()

func CharacterDestroy(_packet: TowerDefensePacketConfig, pos: Vector2, _gridPos: Vector2, _camp: TowerDefenseEnum.CHARACTER_CAMP, _scale: float = 1.0, _hitpointScale: float = 1.0) -> void :
    if !is_instance_valid(_packet):
        return
    if !_packet.characterConfig is TowerDefenseZombieConfig:
        return
    if _packet.saveKey == "ZombieAngel":
        return
    if pos.x < GetMapCellPos(Vector2(4, 0)).x:
        return
    deathList.append(
        {
            "Packet": _packet, 
            "Pos": pos, 
            "GridPos": _gridPos, 
            "Time": TowerDefenseManager.runGameTime, 
            "Camp": _camp, 
            "Scale": _scale, 
            "HitpointScale": _hitpointScale
        }
    )


















func IsIZMMode() -> bool:
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        if is_instance_valid(LevelEditorInformationEditor.instance):
            if is_instance_valid(LevelEditorInformationEditor.instance.levelConfig):
                if LevelEditorInformationEditor.instance.levelConfig.finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
                    return true
        else:
            return false
    else:
        if TowerDefenseManager.GetGameMethod() == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            return true
        if TowerDefenseManager.GetGameMethod() == TowerDefenseEnum.LEVEL_FINISH_METHOD.QUIZ:
            return true
    return false

func IsIZM2Mode() -> bool:
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        if is_instance_valid(LevelEditorInformationEditor.instance):
            if is_instance_valid(LevelEditorInformationEditor.instance.levelConfig):
                if LevelEditorInformationEditor.instance.levelConfig.finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
                    return true
        else:
            return false
    else:
        if TowerDefenseManager.GetGameMethod() == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
            return true
    return false

func IsGameRunning() -> bool:
    if is_instance_valid(currentControl):
        return currentControl.isGameRunning
    return false

func IsUnlimitedFire() -> bool:
    return CommandManager.debugUnlimitedFire

func GetGameMethod() -> TowerDefenseEnum.LEVEL_FINISH_METHOD:
    if is_instance_valid(currentControl):
        return currentControl.levelConfig.finishMethod
    return TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE

func GetCharacterNode() -> Node2D:
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage" && is_instance_valid(LevelEditorMapEditor.instance):
        return LevelEditorMapEditor.instance.characterNode
    if !is_instance_valid(currentControl):
        return ObjectManager
    return currentControl.characterNode





func GetBackgroundMusicConfig(backgroundMusic: String) -> TowerDefenseBackgroundMusicConfig:
    var bgm: TowerDefenseBackgroundMusicConfig = null
    if ResourceManager.BGMS.has(backgroundMusic):
        bgm = ResourceManager.BGMS[backgroundMusic]
    var modBgmGet: TowerDefenseBackgroundMusicConfig = ModManager.FindBgm(backgroundMusic)
    if is_instance_valid(modBgmGet):
        bgm = modBgmGet
    return bgm





func GetPacketBank() -> TowerDefenseInGamePacketBank:
    var packetBankFeature: TowerDefenseBattleFeaturePacketBank = GetPacketBankFeature()
    if packetBankFeature:
        return packetBankFeature.packetBank
    return null

func GetPacketBankFeature() -> TowerDefenseBattleFeaturePacketBank:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("PacketBank")
    return null

func GetPacketBankData(packetBank: String) -> TowerDefensePacketBankData:
    return ResourceManager.TOWERDEFENSE_PACKETBANKS[packetBank]

func GetPacketConfig(packetName: String) -> TowerDefensePacketConfig:
    return ResourceManager.GetPacket(packetName).duplicate(true)

func GetPacketConfigReadOnly(packetName: String) -> TowerDefensePacketConfig:
    return ResourceManager.GetPacket(packetName)

func GetPacketConfigCostUpper(cost: int, type: TowerDefenseEnum.PACKET_TYPE) -> Array[TowerDefensePacketConfig]:
    var packetConfigList: Array[TowerDefensePacketConfig] = []
    ResourceManager.EnsureAllPacketsLoaded()
    for packetConfig: TowerDefensePacketConfig in ResourceManager.TOWERDEFENSE_PACKETS.values():
        if !packetConfig.characterConfig is TowerDefensePlantConfig && !packetConfig.characterConfig is TowerDefenseZombieConfig:
            continue
        if packetConfig.GetCost() >= cost && packetConfig.GetType() == type:
            packetConfigList.append(packetConfig.duplicate(true))
    return packetConfigList

func GetPacketConfigCostUpperWithTypeList(cost: int, typeList: Array[TowerDefenseEnum.PACKET_TYPE]) -> Array[TowerDefensePacketConfig]:
    var packetConfigList: Array[TowerDefensePacketConfig] = []
    ResourceManager.EnsureAllPacketsLoaded()
    for packetConfig: TowerDefensePacketConfig in ResourceManager.TOWERDEFENSE_PACKETS.values():
        if !packetConfig.characterConfig is TowerDefensePlantConfig && !packetConfig.characterConfig is TowerDefenseZombieConfig:
            continue
        if packetConfig.GetCost() >= cost && typeList.has(packetConfig.GetType()):
            packetConfigList.append(packetConfig.duplicate(true))
    return packetConfigList

func GetPacketConfigCostLower(cost: int, type: TowerDefenseEnum.PACKET_TYPE) -> Array[TowerDefensePacketConfig]:
    var packetConfigList: Array[TowerDefensePacketConfig] = []
    ResourceManager.EnsureAllPacketsLoaded()
    for packetConfig: TowerDefensePacketConfig in ResourceManager.TOWERDEFENSE_PACKETS.values():
        if !packetConfig.characterConfig is TowerDefensePlantConfig && !packetConfig.characterConfig is TowerDefenseZombieConfig:
            continue
        if packetConfig.GetCost() <= cost && (packetConfig.GetType() == type || type == TowerDefenseEnum.PACKET_TYPE.NOONE):
            packetConfigList.append(packetConfig.duplicate(true))
    return packetConfigList

func GetPacketConfigCostLowerWithTypeList(cost: int, typeList: Array[TowerDefenseEnum.PACKET_TYPE]) -> Array[TowerDefensePacketConfig]:
    var packetConfigList: Array[TowerDefensePacketConfig] = []
    ResourceManager.EnsureAllPacketsLoaded()
    for packetConfig: TowerDefensePacketConfig in ResourceManager.TOWERDEFENSE_PACKETS.values():
        if !packetConfig.characterConfig is TowerDefensePlantConfig && !packetConfig.characterConfig is TowerDefenseZombieConfig:
            continue
        if packetConfig.GetCost() <= cost && typeList.has(packetConfig.GetType()):
            packetConfigList.append(packetConfig.duplicate(true))
    return packetConfigList

func SpawnPacket(packetConfig: TowerDefensePacketConfig, pos: Vector2, aliveTime: float, isFall: bool, useCost: bool = false) -> TowerDefenseInGamePacketShow:
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return null
    var height: float = randf_range(TowerDefenseManager.GetMapGridBeginPos().y + 200, TowerDefenseManager.GetMapGroundDown() - TowerDefenseManager.GetMapGridBeginPos().y)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    packet.global_position = pos
    characterNode.add_child(packet)
    packet.Init(packetConfig)
    packet.onlyDraw = false
    packet.showCost = useCost
    packet.useCost = useCost
    packet.plantOnce = true
    packet.StartInit()
    packet.alive = true
    packet.aliveTime = aliveTime
    packet.z_index = 1024
    if useCost:
        packet.start = true
    var velocity_x: float = 0.0
    var velocity_y: float = -300.0
    if isFall:
        var tween = packet.create_tween()
        tween.tween_property(packet, ^"global_position:y", height, (height - global_position.y) / 25.0)
    else:
        packet.height = 1
        packet.moveComponent.gravity = 980.0
        velocity_x = randf_range(-50, -30) if randf() > 0.5 else randf_range(30, 50)
        velocity_y = -300.0
        packet.moveComponent.velocity = Vector2(velocity_x, velocity_y)
    packet.pressed.connect(TowerDefenseManager.GetPacketPickControl().PickPacket)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var sync_id: int = control._get_next_packet_sync_id()
            packet.set_meta("packet_sync_id", sync_id)
            control._register_sync_packet(sync_id, packet)
            MultiPlayerManager.SendPacketSpawn(sync_id, packetConfig.saveKey, pos.x, pos.y, aliveTime, isFall, useCost, velocity_x, velocity_y, packet.z_index, height)
    return packet





func GetPortalFeature() -> TowerDefenseBattleFeaturePortal:
    if is_instance_valid(currentControl):
        var portalFeature: TowerDefenseBattleFeaturePortal = currentControl.GetFeature("Portal")
        if portalFeature:
            return portalFeature
    return null

func ProtalCreate(shape: String, posRange: Vector4i, changeTime: float = 0.0) -> void :
    var portalFeature: TowerDefenseBattleFeaturePortal = GetPortalFeature()
    if portalFeature:
        portalFeature.ProtalCreate(shape, posRange, changeTime)

func ProtalChangePos() -> void :
    var portalFeature: TowerDefenseBattleFeaturePortal = GetPortalFeature()
    if portalFeature:
        portalFeature.ProtalChangePos()





func GetChangeCostList() -> Array[TowerDefensePacketChangeCost]:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.changeCostList
    return []

func ChangeCostAdd(changeCost: TowerDefensePacketChangeCost) -> bool:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.ChangeCostAdd(changeCost)
    return false

func ChangeCostRemove(changeCost: TowerDefensePacketChangeCost) -> bool:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.ChangeCostRemove(changeCost)
    return false

func GetSeedBankFeature() -> TowerDefenseBattleFeatureSeedBank:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("SeedBank")
    return null

func GetSeedBank() -> TowerDefenseInGameSeedBank:
    var seedBankFeature: TowerDefenseBattleFeatureSeedBank = GetSeedBankFeature()
    if seedBankFeature:
        return seedBankFeature.seedBank
    return null

func GetRainModeFeature() -> TowerDefenseBattleFeatureRainMode:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("RainMode")
    return null

func GetConveyorBeltFeature() -> TowerDefenseBattleFeatureConveyorBelt:
    var conveyorBeltFeature: TowerDefenseBattleFeatureConveyorBelt = currentControl.GetFeature("ConveyorBelt")
    if conveyorBeltFeature:
        return conveyorBeltFeature
    return null

func GetGloveFeature() -> TowerDefenseBattleFeatureGlove:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("Glove")
    return null

func GetScreenEffectFeature() -> TowerDefenseBattleFeatureScreenEffect:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("ScreenEffect")
    return null

func GetPacketSlotNum() -> int:
    var num: int = 7
    for id in range(8, 17):
        if GameSaveManager.GetFeatureValue("PacketSlot%d" % id) > 0:
            num += 1
        else:
            break
    seedbankPacketMax = num
    return num

func AddPacket(packetName: String, override: TowerDefensePacketOverride = null) -> void :
    var seedBank: TowerDefenseInGameSeedBank = GetSeedBank()
    var packetConfig: TowerDefensePacketConfig = GetPacketConfig(packetName)
    if is_instance_valid(override):
        packetConfig.override = override
    seedBank.AddPacket(packetConfig, true)

func GetSeedBankList() -> Array[TowerDefenseInGamePacketShow]:
    var seedBank: TowerDefenseInGameSeedBank = GetSeedBank()
    if is_instance_valid(seedBank):
        return seedBank.packetList
    return []

func AddSun(num: int) -> void :
    var sunFeature: TowerDefenseBattleFeatureSun = GetSunFeature()
    if sunFeature:
        if Global.isMultiplayerMode and num > 0:
            num = maxi(1, floor(float(num) / 2))
        sunFeature.AddSun(num)

func UseSun(num: int) -> void :
    var sunFeature: TowerDefenseBattleFeatureSun = GetSunFeature()
    if sunFeature:
        sunFeature.UseSun(num)

func SetSun(num: int) -> void :
    var sunFeature: TowerDefenseBattleFeatureSun = GetSunFeature()
    if sunFeature:
        sunFeature.SetSun(num)

func GetSun() -> int:
    var sunFeature: TowerDefenseBattleFeatureSun = GetSunFeature()
    if sunFeature:
        return sunFeature.sunNum
    return -1





func SetNextLevel(levelChoose: String, chapterId: int, levelId: int) -> TowerDefenseLevelConfig:
    var currentChapter = LEVEL_RESOURCE.data[levelChoose]["Chapter"][chapterId]
    var levelList = currentChapter["Level"]
    if levelId + 1 < levelList.size():
        var nextLevel = levelList[levelId + 1]
        if nextLevel["OpenKey"] == "Lock":
            return null
        if (nextLevel["OpenKey"] != ""):
            var levelData: Dictionary = GameSaveManager.GetLevelValue(nextLevel["OpenKey"])
            if levelData.get_or_add("Key", {}).get_or_add("Finish", 0) <= 0:
                return null
        var difficult: String = GameSaveManager.GetKeyValue("CurrentDifficult")
        if nextLevel["Level"][difficult] != "":
            TowerDefenseManager.currentLevelConfig = load(nextLevel["Level"][difficult])
        else:
            TowerDefenseManager.currentLevelConfig = load(nextLevel["Level"]["Normal"])
        Global.currentLevelId = levelId + 1
        GameSaveManager.SetKeyValue("AdventureChapter%dIndex" % [chapterId + 1], levelId + 1)
        GameSaveManager.Save()
        return TowerDefenseManager.currentLevelConfig
    return null

func GetLevelControl() -> TowerDefenseInGameLevelControl:
    if !is_instance_valid(currentControl):
        return null
    return currentControl.levelControl

func GetLevelChapterFinishNum(levelListName: String, chapterName: String) -> int:
    if !LEVEL_RESOURCE.data.has(levelListName):
        return -1
    var levelListData = LEVEL_RESOURCE.data.get(levelListName)
    var chapterList = levelListData["Chapter"]
    for chapterData: Dictionary in chapterList:
        if chapterData["Name"] != chapterName:
            continue
        var finishNum: int = 0
        var chapterLevelList: Array = chapterData["Level"]
        for chapterLevelData in chapterLevelList:
            var levelData: Dictionary = GameSaveManager.GetLevelValue(chapterLevelData["SaveKey"])
            if levelData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0:
                finishNum += 1
        return finishNum
    return -1

func GetLevelEvent(eventName: String) -> TowerDefenseLevelEventBase:
    return ResourceManager.TOWERDEFENSE_LEVEL_EVENT[eventName].new()

func GetLevelHomeworld() -> GeneralEnum.HOMEWORLD:
    var levelControl: TowerDefenseInGameLevelControl = GetLevelControl()
    if !levelControl:
        return GeneralEnum.HOMEWORLD.NOONE
    return levelControl.config.homeWorld

func ExecuteLevelEvent(eventList: Array[TowerDefenseLevelEventBase]) -> void :
    for event: TowerDefenseLevelEventBase in eventList:
        @warning_ignore("redundant_await")
        await event.Execute()

func TipsPlay(text: String, duration: float = 2.0):
    if Global.isMultiplayerMode and is_instance_valid(currentControl):
        @warning_ignore("redundant_await")
        await currentControl.TipsPlay(text, duration)
    else:
        var levelControl: TowerDefenseInGameLevelControl = GetLevelControl()
        await levelControl.TipsPlay(text, duration)

func CreatePacketShow(packetName: String = ""):
    var config: TowerDefensePacketConfig = null
    if packetName != "":
        config = TowerDefenseManager.GetPacketConfig(packetName)
    return CreatePacketShowWithConfig(config)

func CreatePacketShowWithConfig(config: TowerDefensePacketConfig = null):
    var packet: TowerDefenseInGamePacketShow = TOWER_DEFENSE_IN_GAME_PACKET_SHOW.instantiate() as TowerDefenseInGamePacketShow
    if is_instance_valid(config):
        packet.Init(config)
    return packet

func CreateAward(type: TowerDefenseEnum.LEVEL_REWARDTYPE, itemName: String, pos: Vector2) -> TowerDefenseAwardBase:
    match type:
        TowerDefenseEnum.LEVEL_REWARDTYPE.NOONE:
            var instance = TOWER_DEFENSE_AWARD_PURSE.instantiate()
            var characetNode: Node2D = GetCharacterNode()
            characetNode.add_child(instance)
            instance.global_position = pos
            instance.Init(itemName)
            return instance
        TowerDefenseEnum.LEVEL_REWARDTYPE.PACKET:
            var instance = TOWER_DEFENSE_AWARD_PACKET.instantiate()
            var characetNode: Node2D = GetCharacterNode()
            characetNode.add_child(instance)
            instance.global_position = pos
            instance.Init(itemName)
            return instance
        TowerDefenseEnum.LEVEL_REWARDTYPE.COLLECTABLE:
            var instance = TOWER_DEFENSE_AWARD_COLLECTABLE.instantiate()
            var characetNode: Node2D = GetCharacterNode()
            characetNode.add_child(instance)
            instance.global_position = pos
            instance.Init(itemName)
            return instance
        TowerDefenseEnum.LEVEL_REWARDTYPE.COIN:
            var instance = TOWER_DEFENSE_AWARD_PURSE.instantiate()
            var characetNode: Node2D = GetCharacterNode()
            characetNode.add_child(instance)
            instance.global_position = pos
            instance.Init(itemName)
            return instance
        TowerDefenseEnum.LEVEL_REWARDTYPE.TROPHY:
            var instance = TOWER_DEFENSE_AWARD_TROPHY.instantiate()
            var characetNode: Node2D = GetCharacterNode()
            characetNode.add_child(instance)
            instance.global_position = pos
            instance.Init(itemName)
            return instance
    return null

func PickRandomZomie(zombiePool: Array) -> String:
    var weightPick: Array[WeightPickItemBase] = []
    for zombieName: String in zombiePool:
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombieName)
        var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
        var spawn: TowerDefenseLevelSpawnConfig = TowerDefenseLevelSpawnConfig.new()
        spawn.zombie = zombieName
        if characterConfig is TowerDefenseZombieConfig:
            var weight: int = packetConfig.GetWeight()
            var weightPickItem: WeightPickItemBase = WeightPickItemBase.new(spawn, weight)
            weightPick.append(weightPickItem)
    if weightPick.size() > 0:
        var item: WeightPickItemBase = WeightPickMathine.Pick(weightPick)
        return item.item.zombie
    return ""




func GetSunFeature() -> TowerDefenseBattleFeatureSun:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("Sun")
    return null

func SunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.LAND, height: float = 0.0, velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), gravity: float = 980.0, moveStopTime: float = -1) -> TowerDefenseSunBase:
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        return BrainSunCreate(pos, sunNum, movingMethod, height, velocity, gravity, moveStopTime)
    var characterNode: Node2D = GetCharacterNode()
    var sun: TowerDefenseSun = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.SUN, characterNode)
    sun.global_position = pos
    sun.Init(sunNum, movingMethod, height, velocity, gravity, moveStopTime)
    return sun

func BrainSunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.LAND, height: float = 0.0, velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), gravity: float = 980.0, moveStopTime: float = -1) -> TowerDefenseSunBase:
    var characterNode: Node2D = GetCharacterNode()
    var sun: TowerDefenseBrainSun = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.SUN_BRAIN, characterNode)
    sun.global_position = pos
    sun.Init(sunNum, movingMethod, height, velocity, gravity, moveStopTime)
    return sun

func JalapenoSunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.LAND, height: float = 0.0, velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), gravity: float = 980.0, moveStopTime: float = -1) -> TowerDefenseSunBase:
    var characterNode: Node2D = GetCharacterNode()
    var sun: TowerDefenseSunJalapeno = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.SUN_JALAPENO, characterNode)
    sun.global_position = pos
    sun.Init(sunNum, movingMethod, height, velocity, gravity, moveStopTime)
    return sun





func GetCoin() -> int:
    if coinBank:
        return coinBank.num
    return 0

func AddCoin(num: int) -> void :
    if coinBank:
        coinBank.AddNum(num)

func UseCoin(num: int) -> void :
    if coinBank:
        coinBank.UseCoin(num)

func CoinCreate(pos: Vector2, num: int, height: float = 0.0, velocity: Vector2 = Vector2.ZERO, gravity: float = 0.0, _collect: bool = false) -> void :
    var characterNode = GetCharacterNode()
    while num >= 1000:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_DIAMOND, pos, height, velocity, gravity)
        item.gridPos.y = 200
        item.reparent(characterNode, false)
        if _collect:
            item.Collection()
        num -= 1000
        await get_tree().create_timer(0.1, false).timeout
    while num >= 50:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, pos, height, velocity, gravity)
        item.gridPos.y = 200
        item.reparent(characterNode, false)
        if _collect:
            item.Collection()
        num -= 50
        await get_tree().create_timer(0.1, false).timeout
    while num >= 10:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, pos, height, velocity, gravity)
        item.gridPos.y = 200
        item.reparent(characterNode, false)
        if _collect:
            item.Collection()
        num -= 10
        await get_tree().create_timer(0.1, false).timeout

func YBCreate(pos: Vector2, num: int, height: float = 0.0, velocity: Vector2 = Vector2.ZERO, gravity: float = 0.0, _collect: bool = false) -> void :
    var characterNode = GetCharacterNode()
    while num >= 1000:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_YB2, pos, height, velocity, gravity)
        item.gridPos.y = 200
        item.reparent(characterNode, false)
        if _collect:
            item.Collection()
        num -= 1000
        await get_tree().create_timer(0.1, false).timeout
    while num >= 50:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_YB1, pos, height, velocity, gravity)
        item.gridPos.y = 200
        item.reparent(characterNode, false)
        if _collect:
            item.Collection()
        num -= 50
        await get_tree().create_timer(0.1, false).timeout
    while num >= 10:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_TQ, pos, height, velocity, gravity)
        item.gridPos.y = 200
        item.reparent(characterNode, false)
        if _collect:
            item.Collection()
        num -= 10
        await get_tree().create_timer(0.1, false).timeout

func LuckyBagCreate(pos: Vector2, height: float = 0.0, velocity: Vector2 = Vector2.ZERO, gravity: float = 0.0) -> void :
    var characterNode = GetCharacterNode()
    var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_LUCKY_BAG, pos, height, velocity, gravity)
    item.gridPos.y = 200
    item.reparent(characterNode, false)





func FallingObjectCreate(pos: Vector2, height: float = 0.0, velocity: Vector2 = Vector2.ZERO, gravity: float = 0.0) -> Node2D:
    var id: ObjectManagerConfig.OBJECT = ZOMBIE_DEATH_FALLING_OBJECT.Pick()
    if id == ObjectManagerConfig.OBJECT.NOONE:
        return null
    return FallingObjectItemCreate(id, pos, height, velocity, gravity)

func FallingObjectItemCreate(id: ObjectManagerConfig.OBJECT, pos: Vector2, height: float = 0.0, velocity: Vector2 = Vector2.ZERO, gravity: float = 0.0) -> Node2D:
    if id == ObjectManagerConfig.OBJECT.NOONE:
        return null
    var characterNode: Node2D = GetCharacterNode()
    var item = ObjectManager.PoolPop(id, characterNode)
    item.global_position = pos
    if item is TowerDefenseCoinBase:
        var config: DropItemConfig = DropItemRegistry.GetById(id)
        if config && config.value > 0:
            item.num = config.value
        item.Init(height, velocity, gravity)
    return item





func GetMapControl() -> TowerDefenseMapControl:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.mapControl
    return null

func GetMapFeature() -> TowerDefenseBattleFeatureMap:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("Map")
    if is_instance_valid(LevelEditorMapEditor.instance) && is_instance_valid(LevelEditorMapEditor.instance.mapFeature):
        return LevelEditorMapEditor.instance.mapFeature
    return null

func MapDayNightSwitch(duration: float = 2.0, _switchTimer: float = 100.0) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        mapFeature.MapDayNightSwitch(duration, _switchTimer)

func MapLineHasType(line: int, type: TowerDefenseEnum.PLANTGRIDTYPE) -> bool:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.LineHasType(line, type)
    return false

func GetCurrentMapConfig() -> TowerDefenseMapConfig:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.config
    return null

func GetMapPlantGrid() -> Array[Array]:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.plantGrid
    return []

func GetMapLineUseArr() -> Array[bool]:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.lineUse
    return []

func GetMapIceCapList() -> Array:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.iceCapList
    return []

func GetMapCurrentMap() -> TowerDefenseMap:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.currentMap
    return null

func GetPacketPickControl() -> PacketPickControl:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.packetPickControl
    return null

func GetGroundRect() -> Rect2:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        return mapFeature.groundRect
    return Rect2()

func SetIceCapPos(line: int, pos: Vector2) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        mapFeature.SetIceCapPos(line, pos)

func GetMapIsChess() -> bool:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config):
        return mapFeature.config.isChess
    return false

func GetMapIsVampire() -> bool:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config):
        return mapFeature.config.isVampire
    return false

func GetCurrentMap() -> TowerDefenseMap:
    return GetMapCurrentMap()

func GetMapConfig(mapName: String) -> TowerDefenseMapConfig:
    var map: TowerDefenseMapConfig = null
    if ResourceManager.MAPS.has(mapName):
        map = ResourceManager.MAPS[mapName]
    var modMapGet: TowerDefenseMapConfig = ModManager.FindMap(mapName)
    if is_instance_valid(modMapGet):
        map = modMapGet
    return map

func MapChange(map: String, duration: float = 0.0, delay = 0.0) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        var _config: TowerDefenseMapConfig = GetMapConfig(map)
        if is_instance_valid(_config):
            await mapFeature.MapChange(_config, duration, delay)

func GetMapIsNight() -> bool:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config):
        return mapFeature.config.isNight
    return false

func SetMapGridType(cellConfig: TowerDefenseCellConfig) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        mapFeature.SetGridType(cellConfig)

func SetMapLineUse(line: int, use: bool) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature):
        mapFeature.SetLineUse(line, use)

func GetMapLineUse(line: int) -> bool:
    return GetMapLineUseArr()[line]

func GetMapGridNum() -> Vector2i:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config):
        return mapFeature.config.gridNum
    else:
        return Vector2i(25, 25)

func GetMapGridSize() -> Vector2:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config) && is_instance_valid(mapFeature.mapControl):
        return mapFeature.config.gridSize * mapFeature.mapControl.global_scale
    else:
        return Vector2(80.0, 98.0)

func GetMapGridBeginPos() -> Vector2:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config) && is_instance_valid(mapFeature.mapControl):
        return mapFeature.config.gridBeginPos * mapFeature.mapControl.global_scale + mapFeature.mapControl.global_position
    else:
        return Vector2(0, 0)

func GetMapGridPosFromMouse(pos: Vector2) -> Vector2i:
    var xPos: int = floor((pos.x - gridBeginPos.x) / gridSize.x)
    var percentage: float = (pos.x - (gridBeginPos.x + xPos * gridSize.x)) / gridSize.x
    for yPos in range(0, gridNum.y, 1):
        var checkPos: Vector2i = Vector2i(xPos, yPos) + Vector2i.ONE
        var cell = GetMapCell(checkPos)
        if is_instance_valid(cell):
            var groundHeight = 0
            if is_instance_valid(cell.groundHeightCurve):
                groundHeight = cell.groundHeightCurve.curve.sample(percentage)
            if pos.y > (gridBeginPos.y + yPos * gridSize.y) - groundHeight && pos.y < (gridBeginPos.y + yPos * gridSize.y) - groundHeight + gridSize.y:
                return checkPos
    return Vector2(xPos, -1)

func GetMapGridPos(pos: Vector2) -> Vector2i:
    var gridPos: Vector2i = Vector2i(((pos - gridBeginPos) / gridSize).floor()) + Vector2i.ONE
    return gridPos

func GetMapCellPos(gridPos: Vector2i) -> Vector2:
    gridPos -= Vector2i.ONE
    var pos: Vector2 = gridBeginPos + Vector2(gridPos) * gridSize
    return pos

func GetMapCellPosCenter(gridPos: Vector2i) -> Vector2:
    gridPos -= Vector2i.ONE
    var pos: Vector2 = gridBeginPos + Vector2(gridPos) * gridSize + GetMapGridSize() / 2.0
    return pos

func GetMapPlantOffset() -> float:
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config):
        return mapFeature.config.plantOffset
    return 50

func GetMapCellPlantPos(gridPos: Vector2i) -> Vector2:
    gridPos -= Vector2i.ONE
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    var pos: Vector2 = gridBeginPos + Vector2(gridPos) * gridSize + Vector2(gridSize.x / 2, GetMapPlantOffset() * mapFeature.mapControl.global_scale.y)
    return pos

func GetMapLineY(line: int) -> float:
    line -= 1
    var mapFeature: TowerDefenseBattleFeatureMap = GetMapFeature()
    var y: float = gridBeginPos.y + line * gridSize.y + GetMapPlantOffset() * mapFeature.mapControl.global_scale.y
    return y

func CheckMapGridPosIn(gridPos: Vector2i) -> bool:
    if gridPos.x < 1 || gridPos.y < 1 || gridPos.x > gridNum.x || gridPos.y > gridNum.y:
        return false
    return true

func GetMapCell(gridPos: Vector2i) -> TowerDefenseCellInstance:
    var _plantGrid: Array[Array] = GetMapPlantGrid()
    if _plantGrid.is_empty():
        return null
    if gridPos.x < 1 || gridPos.y < 1 || gridPos.x > gridNum.x || gridPos.y > gridNum.y:
        return null
    if _plantGrid.size() <= gridPos.x:
        return null
    if _plantGrid[gridPos.x][gridPos.y] == null:
        return null
    return _plantGrid[gridPos.x][gridPos.y]


func GetMapGroundLeft() -> float:
    return gridBeginPos.x

func GetMapGroundRight() -> float:
    return gridBeginPos.x + gridNum.x * gridSize.x

func GetMapGroundUp() -> float:
    return gridBeginPos.y

func GetMapGroundDown() -> float:
    return gridBeginPos.y + gridNum.y * gridSize.y





func GetMowerConfig(mowerName: String) -> MowerConfig:
    return ResourceManager.MOWERS[mowerName]

func GetMowerList() -> Array:
    return ResourceManager.MOWERS.keys()

func GetMowerNum() -> int:
    return GetMower().size()

func GetMower() -> Array:
    return get_tree().get_nodes_in_group("Mower")

func CreateMower(line: int) -> TowerDefenseMower:
    var mowerFeature: TowerDefenseBattleFeatureMower = GetMowerFeature()
    if mowerFeature:
        return mowerFeature.CreateMower(line)
    return null

func GetMowerFeature() -> TowerDefenseBattleFeatureMower:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("Mower")
    return null

func GetMowerManager() -> TowerDefenseMowerManager:
    var mowerFeature: TowerDefenseBattleFeatureMower = GetMowerFeature()
    if mowerFeature:
        return mowerFeature.mowerManager
    return null

func GetBrainFeature() -> TowerDefenseBattleFeatureBrain:
    var control: TowerDefenseControlNew = currentControl
    if control:
        return control.GetFeature("Brain")
    return null

func GetCurrentProcess() -> TowerDefenseBattleProcess:
    var control = currentControl
    return control.process





func GetCharacterSprite(charcterSpriteName: String) -> AdobeAnimateSprite:
    return ResourceManager.GetCharacterSprite(charcterSpriteName).instantiate()

func GetChacraterScene(charcterName: String) -> PackedScene:
    return ResourceManager.GetCharacterScene(charcterName)

func CreateCharacter(characterName: String, gridPos: Vector2i = Vector2i(-1, -1)) -> TowerDefenseCharacter:
    var characterScene: PackedScene = GetChacraterScene(characterName)
    var character: TowerDefenseCharacter = characterScene.instantiate() as TowerDefenseCharacter
    character.gridPos = gridPos
    return character





func GetShovel(shovelName: String) -> ShovelConfig:
    return ResourceManager.SHOVELS[shovelName]

func GetShovelList() -> Array:
    return ResourceManager.SHOVELS.keys()





func GetCollectable(collectableName: String) -> CollectableConfig:
    return ResourceManager.COLLECTABLES[collectableName]





func GetTutorial(tutorialName: String) -> TutorialConfig:
    return ResourceManager.TUTORIALS[tutorialName]





func GetNpcTalk(npcTalkName: String) -> NpcTalkConfig:
    return ResourceManager.TALKS[npcTalkName]





func GetProjectileConfig(projectileName: String) -> TowerDefenseProjectileConfig:
    if ResourceManager.PROJECTILE_CONFIG.has(projectileName):
        return ResourceManager.PROJECTILE_CONFIG[projectileName]
    return null





func GetEffectSprite(effectSpriteName: String) -> AdobeAnimateSprite:
    return ResourceManager.EFFECT_SPRITE[effectSpriteName].instantiate()

func CreateEffectParticlesOnce(scene: PackedScene, gridPos: Vector2i = Vector2i(-1, -1)) -> TowerDefenseEffectParticlesOnce:
    var effect: TowerDefenseEffectParticlesOnce = TOWER_DEFENSE_EFFECT_PARTICLES_ONCE.instantiate() as TowerDefenseEffectParticlesOnce
    effect.Init(scene)
    effect.gridPos = gridPos
    return effect

func CreateEffectSpriteOnce(scene: PackedScene, gridPos: Vector2i = Vector2i(-1, -1), clip: String = "") -> TowerDefenseEffectSpriteOnce:
    var effect: TowerDefenseEffectSpriteOnce = TOWER_DEFENSE_EFFECT_SPRITE_ONCE.instantiate() as TowerDefenseEffectSpriteOnce
    effect.Init(scene, clip)
    effect.gridPos = gridPos
    return effect

func CreateEffectParticlesSceneOnce(scene: GPUParticles2DMerge, gridPos: Vector2i = Vector2i(-1, -1)) -> TowerDefenseEffectParticlesOnce:
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseEffectParticlesOnce.Create()
    effect.InitScene(scene)
    effect.gridPos = gridPos
    return effect

func CreateEffectSpriteSceneOnce(scene: AdobeAnimateSprite, gridPos: Vector2i = Vector2i(-1, -1), clip: String = "") -> TowerDefenseEffectSpriteOnce:
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseEffectSpriteOnce.Create()
    effect.InitScene(scene, clip)
    effect.gridPos = gridPos
    return effect

func GetEffectDirtName() -> String:
    var homeWorld: GeneralEnum.HOMEWORLD = GetLevelHomeworld()
    if !ResourceManager.EFFECT_DIRT_NAME.has(homeWorld):
        return "DirtSpawnDirt"
    return ResourceManager.EFFECT_DIRT_NAME[homeWorld]





func GetPlant() -> Array:
    var plantList = get_tree().get_nodes_in_group("Plant")
    return plantList

func GetZombie() -> Array:
    var zombieList = get_tree().get_nodes_in_group("Zombie")
    return zombieList

func GetCharacter() -> Array:
    var characterList = _GetCleanCharacters().filter(
        func(character):
            return !character.characterFilter
    )
    return characterList

func GetProjectile() -> Array:
    var projectileList = get_tree().get_nodes_in_group("Projectile")
    return projectileList

func GetEffect() -> Array:
    var effectList = get_tree().get_nodes_in_group("Effect")
    return effectList

func GetEffectCount() -> int:
    return characterRegistry.GetEffectCount()

func GetLineCharacters(line: int) -> Array:
    return characterRegistry.GetLineCharacters(line)

func GetCampFriendly(camp: TowerDefenseEnum.CHARACTER_CAMP, fliterGraveStone: bool = true) -> Array:
    var characterList = _GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if checkCharacter.die || checkCharacter.nearDie:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            return checkCharacter.camp == camp
    )
    return characterList

func GetCampFriendlyFromArea(camp: TowerDefenseEnum.CHARACTER_CAMP, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    var areas = _GetOverlappingAreasCached(checkArea)
    var characterList: Array[TowerDefenseCharacter] = []
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue
            if checkCharacter.camp != camp:
                continue
            characterList.append(checkCharacter)
    return characterList

func GetCampFriendlyLine(character: TowerDefenseCharacter, fliterGraveStone: bool = true) -> Array:
    var characterList = _GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false
            return checkCharacter.camp == character.camp && checkCharacter.gridPos.y == character.gridPos.y
    )
    return characterList

func GetCampTarget(camp: TowerDefenseEnum.CHARACTER_CAMP, fliterGraveStone: bool = true) -> Array:
    var characterList = _GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if checkCharacter.die || checkCharacter.nearDie:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            return checkCharacter.camp != camp
    )
    return characterList

func GetCampTargetFromArray(checkArea: Area2D, camp: TowerDefenseEnum.CHARACTER_CAMP, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if checkCharacter.camp == camp:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue
            characterList.append(checkCharacter)
    return characterList

func GetCharacterNum(characterName: String, containConveyor: bool = false) -> int:
    var num: int = GetCharacterFromName(characterName).size()
    if containConveyor:
        var conveyorFeature: TowerDefenseBattleFeatureConveyorBelt = GetConveyorBeltFeature()
        if is_instance_valid(conveyorFeature):
            for packet: TowerDefenseInGamePacketShow in conveyorFeature.GetPacketChildren():
                if packet.config.saveKey == characterName:
                    num += 1
    return num

func GetCharacterFromName(characterName: String) -> Array:
    var characterList = _GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter) -> bool:
            if !checkCharacter.inGame:
                return false
            if checkCharacter.config.name == characterName:
                return true
            return false
    )
    return characterList

func GetProjectileHasTarget(projectile: TowerDefenseProjectile, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    return targetSystem.GetProjectileHasTarget(projectile, checkLine, fliterGraveStone)

func GetProjectileHasTargetFromArray(projectile: TowerDefenseProjectile, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    return targetSystem.GetProjectileHasTargetFromArray(projectile, array, checkLine, fliterGraveStone)

func GetProjectileHasTargetFromArea(projectile: TowerDefenseProjectile, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    return targetSystem.GetProjectileHasTargetFromArea(projectile, checkArea, checkLine, fliterGraveStone)

func GetProjectileTarget(projectile: TowerDefenseProjectile, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetProjectileTarget(projectile, checkLine, fliterGraveStone)

func GetProjectileTargetFromArray(projectile: TowerDefenseProjectile, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetProjectileTargetFromArray(projectile, array, checkLine, fliterGraveStone)

func GetProjectileTargetFromArea(projectile: TowerDefenseProjectile, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetProjectileTargetFromArea(projectile, checkArea, checkLine, fliterGraveStone)

func GetCharacterHasTarget(character: TowerDefenseCharacter, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    return targetSystem.GetCharacterHasTarget(character, checkLine, fliterGraveStone)

func GetCharacterHasTargetFromArray(character: TowerDefenseCharacter, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    return targetSystem.GetCharacterHasTargetFromArray(character, array, checkLine, fliterGraveStone)

func GetCharacterHasTargetFromArea(character: TowerDefenseCharacter, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    return targetSystem.GetCharacterHasTargetFromArea(character, checkArea, checkLine, fliterGraveStone)

func GetCharacterTarget(character: TowerDefenseCharacter, checkLine: bool = false, checkCollision: bool = false, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTarget(character, checkLine, checkCollision, fliterGraveStone)

func GetCharacterTargetFromArray(character: TowerDefenseCharacter, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetFromArray(character, array, checkLine, fliterGraveStone)

func GetCharacterTargetFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetFromArrayWithCollisionFlags(character, collisionFlags, array, checkLine, fliterGraveStone)

func GetCharacterTargetFromArea(character: TowerDefenseCharacter, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true, fliterVase: bool = true) -> Array:
    return targetSystem.GetCharacterTargetFromArea(character, checkArea, checkLine, fliterGraveStone, fliterVase)

func GetCharacterLine(line: int, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterLine(line, fliterGraveStone)

func GetCharacterTargetLine(character: TowerDefenseCharacter, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetLine(character, fliterGraveStone)

func GetCharacterTargetLineWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetLineWithCollisionFlags(character, collisionFlags, fliterGraveStone)

func GetCharacterTargetLineFromArray(character: TowerDefenseCharacter, array: Array, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetLineFromArray(character, array, fliterGraveStone)

func GetCharacterTargetLineFromArea(character: TowerDefenseCharacter, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetLineFromArea(character, checkArea, fliterGraveStone)

func GetCharacterTargetLineFromAreaWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetLineFromAreaWithCollisionFlags(character, collisionFlags, checkArea, fliterGraveStone)

func GetCharacterTargetFromAreaWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterTargetFromAreaWithCollisionFlags(character, collisionFlags, checkArea, fliterGraveStone)

func GetCharacterColumn(column: int, fliterGraveStone: bool = true) -> Array:
    return targetSystem.GetCharacterColumn(column, fliterGraveStone)

func GetCharacterTargetNear(character: TowerDefenseCharacter, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    return targetSystem.GetCharacterTargetNear(character, method, checkLine, fliterGravestone)

func GetCharacterTargetNearFromArray(character: TowerDefenseCharacter, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    return targetSystem.GetCharacterTargetNearFromArray(character, array, method, checkLine, fliterGravestone)

func GetCharacterTargetNearFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    return targetSystem.GetCharacterTargetNearFromArrayWithCollisionFlags(character, collisionFlags, array, method, checkLine, fliterGravestone)

func GetCharacterTargetNearFromArea(character: TowerDefenseCharacter, checkArea: Area2D, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    return targetSystem.GetCharacterTargetNearFromArea(character, checkArea, method, checkLine, fliterGravestone)

func GetNearCharacter(character: TowerDefenseCharacter, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false, fliterVase: bool = true) -> TowerDefenseCharacter:
    return targetSystem.GetNearCharacter(character, method, checkLine, fliterGravestone, fliterVase)

func GetProjectileTargetNear(projectile: TowerDefenseProjectile, collisionFlags: int = -1, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    return targetSystem.GetProjectileTargetNear(projectile, collisionFlags, method, checkLine, fliterGravestone)

func GetProjectileTargetNearProjectile(projectile: TowerDefenseProjectile, collisionFlags: int = -1, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = true) -> Array:
    return targetSystem.GetProjectileTargetNearProjectile(projectile, collisionFlags, method, checkLine, fliterGravestone)

func GetProjectileTargetNearest(projectile: TowerDefenseProjectile, collisionFlags: int = -1, fliterGravestone: bool = true) -> TowerDefenseCharacter:
    return targetSystem.GetProjectileTargetNearest(projectile, collisionFlags, fliterGravestone)

func GetCharacterTargetFarFromArray(character: TowerDefenseCharacter, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    return targetSystem.GetCharacterTargetFarFromArray(character, array, method, checkLine, fliterGravestone)

func GetCharacterTargetFarFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    return targetSystem.GetCharacterTargetFarFromArrayWithCollisionFlags(character, collisionFlags, array, method, checkLine, fliterGravestone)

func BungiSpawn(packetName: String, gridPos: Vector2i, override: TowerDefenseCharacterOverride = null, hypnoses: bool = false) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var zombie: TowerDefenseZombie = TOWER_DEFENSE_ZOMBIE_BUNGI_SPAWN.instantiate() as TowerDefenseZombie
    zombie.characterName = packetName
    zombie.override = override
    zombie.global_position = TowerDefenseManager.GetMapCellPlantPos(gridPos)
    zombie.gridPos = gridPos
    characterNode.add_child(zombie)
    if hypnoses:
        zombie.Hypnoses()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var sync_id: int = currentControl._get_next_sync_id()
        var _hitpoint_scale: float = zombie.instance.hitpointScale if is_instance_valid(zombie.instance) else 1.0
        var _scale: float = zombie.transformPoint.scale.x if is_instance_valid(zombie.transformPoint) else 1.0
        currentControl._register_sync_character(sync_id, zombie)
        MultiPlayerManager.SendSpawnCharacterAt(packetName, gridPos.x, gridPos.y, sync_id, _hitpoint_scale, _scale, hypnoses)
