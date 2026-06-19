class_name TowerDefenseBattleProcessIZM extends TowerDefenseBattleProcess

var config: TowerDefenseLevelIZMManagerConfig

var sunFeature: TowerDefenseBattleFeatureSun
var mapFeature: TowerDefenseBattleFeatureMap
var progressFeature: TowerDefenseBattleFeatureProgess
var cameraFeature: TowerDefenseBattleFeatureCamera
var seedBankFeature: TowerDefenseBattleFeatureSeedBank
var packetBankFeature: TowerDefenseBattleFeaturePacketBank
var brainFeature: TowerDefenseBattleFeatureBrain
var conveyorBeltFeature: TowerDefenseBattleFeatureConveyorBelt

var levelControl: TowerDefenseInGameLevelControl

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelIZMManagerConfig.new()
    config.Init(data)

func Ready() -> void :
    pass

func SetupUI() -> void :
    await GetTree().physics_frame
    var text = tr(TowerDefenseManager.currentLevelConfig.levelName).replace("{LevelNumber}", str(TowerDefenseManager.currentLevelConfig.levelNumber))
    progressFeature.SetLevelName(text)
    progressFeature.SetDifficultVisible(false)

func GameInit() -> void :
    levelControl = control.levelControl

    sunFeature = GetFeature("Sun")
    mapFeature = GetFeature("Map")
    progressFeature = GetFeature("Progess")
    cameraFeature = GetFeature("Camera")
    seedBankFeature = GetFeature("SeedBank")
    packetBankFeature = GetFeature("PacketBank")
    brainFeature = GetFeature("Brain")
    conveyorBeltFeature = GetFeature("ConveyorBelt")

    SetupUI()

func GameInitFromProgress() -> void :
    levelControl = control.levelControl

    sunFeature = GetFeature("Sun")
    mapFeature = GetFeature("Map")
    progressFeature = GetFeature("Progess")
    cameraFeature = GetFeature("Camera")
    seedBankFeature = GetFeature("SeedBank")
    packetBankFeature = GetFeature("PacketBank")
    brainFeature = GetFeature("Brain")
    conveyorBeltFeature = GetFeature("ConveyorBelt")

func Execute(preSpawnlist: Array[TowerDefenseLevelPreSpawnConfig]) -> Array[TowerDefenseCharacter]:
    preSpawnlist = preSpawnlist.duplicate_deep()
    var spawnedCharacters: Array[TowerDefenseCharacter] = []
    var staticPreSpawn: Array[TowerDefenseLevelPreSpawnConfig] = []
    for preSpawn: TowerDefenseLevelPreSpawnConfig in preSpawnlist:
        var packet: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(preSpawn.packetName)
        var characterConfig: TowerDefenseCharacterConfig = packet.characterConfig
        if characterConfig is TowerDefensePlantConfig:
            continue
        staticPreSpawn.append(preSpawn)
    for preSpawn: TowerDefenseLevelPreSpawnConfig in staticPreSpawn:
        preSpawnlist.erase(preSpawn)
    var lineNum = mapFeature.config.gridNum.y
    var rawNum = mapFeature.config.gridNum.x
    var gridList: Array[Array] = []
    var canSwapLine: Array[Array] = []
    var swapLine: Array = []
    for lineId in range(lineNum + 1):
        gridList.append([])
        canSwapLine.append([])
        for rawId in range(rawNum + 1):
            gridList[lineId].append([])
    for lineId in range(1, lineNum + 1, 1):
        canSwapLine[lineId].append(lineId)
        for lineCheckId in range(1, lineNum + 1, 1):
            if lineId == lineCheckId:
                continue
            var flag: bool = true
            for gridX in range(1, rawNum + 1, 1):
                var gridPos: Vector2i = Vector2i(gridX, lineId)
                var gridPosCheck: Vector2i = Vector2i(gridX, lineCheckId)
                var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
                var cellCheck: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPosCheck)
                if cell.gridType != cellCheck.gridType:
                    flag = false
                    break
            if flag:
                if !canSwapLine[lineId].has(lineCheckId):
                    canSwapLine[lineId].append(lineCheckId)
    swapLine.append(-1)
    for lineId in range(1, lineNum + 1, 1):
        if canSwapLine[lineId].size() <= 0:
            continue
        var swapId: int = canSwapLine[lineId].pick_random()
        swapLine.append(swapId)
        for lineRemovedId in range(1, lineNum + 1, 1):
            canSwapLine[lineRemovedId].erase(swapId)
    for preSpawn: TowerDefenseLevelPreSpawnConfig in preSpawnlist:
        var x = preSpawn.gridPos.x
        var y = swapLine[preSpawn.gridPos.y]
        gridList[y][x].append(preSpawn)
    for lineId in range(1, lineNum + 1, 1):
        var swapXList: Array = []
        for rawId in range(1, rawNum + 1, 1):
            for preSpawn: TowerDefenseLevelPreSpawnConfig in gridList[lineId][rawId]:
                swapXList.append(rawId)
        if swapXList.size() > 0:
            for rawId in range(1, rawNum + 1, 1):
                if gridList[lineId][rawId].size() <= 0:
                    continue
                if randf() > 0.5:
                    var moveTo = swapXList.pick_random()
                    var temp = gridList[lineId][moveTo]
                    gridList[lineId][moveTo] = gridList[lineId][rawId]
                    gridList[lineId][rawId] = temp
    for lineId in range(1, lineNum + 1, 1):
        for rawId in range(1, rawNum + 1, 1):
            for preSpawn: TowerDefenseLevelPreSpawnConfig in gridList[lineId][rawId]:
                preSpawn.gridPos = Vector2(rawId, lineId)
    preSpawnlist.append_array(staticPreSpawn)
    var recheckList: Array = []
    for preSpawn: TowerDefenseLevelPreSpawnConfig in preSpawnlist:
        var characterSpawn = preSpawn.SpawnCharacter()
        if !is_instance_valid(characterSpawn):
            recheckList.append(preSpawn)
        else:
            spawnedCharacters.append(characterSpawn)
            if is_instance_valid(preSpawn.characterOverride):
                preSpawn.characterOverride.ExecuteCharacter(characterSpawn)
    for preSpawn: TowerDefenseLevelPreSpawnConfig in recheckList:
        var characterSpawn = preSpawn.SpawnCharacter()
        if is_instance_valid(characterSpawn):
            spawnedCharacters.append(characterSpawn)
            if is_instance_valid(preSpawn.characterOverride):
                preSpawn.characterOverride.ExecuteCharacter(characterSpawn)
    return spawnedCharacters

func GameEntry() -> void :
    if control.hasProgress:
        if seedBankFeature:
            seedBankFeature.seedBank.packetSlotContainer.visible = true
        if GameSaveManager.GetConfigValue("MobilePreset"):
            control.uiTopAnimationPlayer.play("MobileEnter")
        else:
            control.uiTopAnimationPlayer.play("Enter")
        if packetBankFeature:
            packetBankFeature.packetBank.visible = false
        return
    if packetBankFeature and !packetBankFeature.skipPacketChoose:
        if GameSaveManager.GetConfigValue("MobilePreset"):
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileEnter")
            control.uiTopAnimationPlayer.play("MobileEnter")
        else:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Enter")
            control.uiTopAnimationPlayer.play("Enter")
        control.buttonPause.visible = true
        if seedBankFeature:
            seedBankFeature.seedBank.packetSlotContainer.visible = true
        await packetBankFeature.chooseOver
        if seedBankFeature:
            seedBankFeature.seedBank.Ready()
        if GameSaveManager.GetConfigValue("MobilePreset"):
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileExit")
        else:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Exit")
        await GetTree().create_timer(0.5, false).timeout
    else:
        if seedBankFeature:
            seedBankFeature.seedBank.Ready()
        if GameSaveManager.GetConfigValue("MobilePreset"):
            control.uiTopAnimationPlayer.play("MobileEnter")
        else:
            control.uiTopAnimationPlayer.play("Enter")
    GameReady()
    GameStart()

func GameReady() -> void :
    if !levelControl:
        return
    if !control.hasProgress:
        if brainFeature:
            brainFeature.BrainInit()
    if progressFeature:
        progressFeature.SetProgressMeterMaxValue(GetTree().get_node_count_in_group("Brain"))
        progressFeature.SetProgressMeterWaveNum(GetTree().get_node_count_in_group("Brain"))
        progressFeature.SetProgressMeterPreviewWave(0)
        progressFeature.SetProgressMeterValue(0)
        progressFeature.SetLevelNameVisible(true)
        if Global.enterLevelMode == "DailyLevel" || Global.enterLevelMode == "OnlineLevel" || Global.enterLevelMode == "LevelTest" || Global.enterLevelMode == "DiyLevel":
            progressFeature.SetDifficultVisible(false)

func GameStart() -> void :
    if progressFeature:
        progressFeature.SetProgressMeterHideItem(true)
        progressFeature.SetProgressMeterVisible(true)

func GameStartFromProgress() -> void :
    if progressFeature:
        progressFeature.SetProgressMeterHideItem(true)
        progressFeature.SetProgressMeterVisible(true)

@warning_ignore("unused_parameter")
func GameFail(enterCharacter: TowerDefenseCharacter) -> void :
    control.ZombieWonLevelFail(false)

func ZombieEnterHouse(character: TowerDefenseCharacter) -> void :
    var tween = character.create_tween()
    tween.tween_property(character.sprite, "meshColor:a", 0.0, 1.0).finished.connect(
        func():
            if is_instance_valid(character):
                character.Destroy()
    )

func ViewMap() -> void :
    if GameSaveManager.GetConfigValue("MobilePreset"):
        if packetBankFeature.packetBank:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileExit")
    else:
        if packetBankFeature.packetBank:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Exit")
    if seedBankFeature:
        for packet: Node in seedBankFeature.seedBank.packetContainer.get_children():
            if packet is TowerDefenseInGamePacketShow:
                packet.onlyDraw = true
    control.isView = true
    var broadCastConfig: BroadCastConfig = BroadCastConfig.new()
    broadCastConfig.broadCastString = "INGAME_VIEW_BACK"
    BroadCastManager.BroadCastAdd(broadCastConfig)
    await control.viewBack
    BroadCastManager.BraodCastClear()
    control.isView = false
    if seedBankFeature:
        for packet: Node in seedBankFeature.seedBank.packetContainer.get_children():
            if packet is TowerDefenseInGamePacketShow:
                packet.onlyDraw = false
    if GameSaveManager.GetConfigValue("MobilePreset"):
        if packetBankFeature.packetBank:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileEnter")
    else:
        if packetBankFeature.packetBank:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Enter")

@warning_ignore("unused_parameter")
func InputProcess(event: InputEvent) -> void :
    if control && control.isView:
        if Input.is_anything_pressed():
            control.viewBack.emit()

func CheckFinal() -> bool:
    if !levelControl:
        return false
    var brainList = GetTree().get_nodes_in_group("Brain")
    if brainList.size() > 0:
        levelControl.awardPos = brainList[0].global_position
    else:
        return true
    return false

func CheckFail() -> bool:
    if GetTree().get_node_count_in_group("Sun") > 0 || GetTree().get_node_count_in_group("BrainSun") > 0 || GetTree().get_node_count_in_group("JalapenoSun") > 0:
        return false
    var sunNum = TowerDefenseManager.GetSun()
    var canUseCheckFlag: bool = true
    if seedBankFeature:
        for packet: TowerDefenseInGamePacketShow in seedBankFeature.seedBank.packetList:
            if sunNum >= packet.itemCost:
                canUseCheckFlag = false
                break
    if canUseCheckFlag && conveyorBeltFeature:
        if conveyorBeltFeature.IsSunType():
            for packet: Node in conveyorBeltFeature.conveyorBeltManager.GetPacketChildren():
                if packet is TowerDefenseInGamePacketShow:
                    if !packet.useCost || sunNum >= packet.itemCost:
                        canUseCheckFlag = false
                        break
            if canUseCheckFlag:
                for conveyorPacketConfig: TowerDefenseConveyorPacketConfig in conveyorBeltFeature.packetList:
                    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(conveyorPacketConfig.name)
                    if is_instance_valid(packetConfig) && sunNum >= packetConfig.GetCost():
                        canUseCheckFlag = false
                        break
            if canUseCheckFlag:
                for levelPacketConfig: TowerDefenseLevelPacketConfig in conveyorBeltFeature.packetPrioritySpawnList:
                    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(levelPacketConfig.packetName)
                    if is_instance_valid(packetConfig) && sunNum >= packetConfig.GetCost():
                        canUseCheckFlag = false
                        break
        else:
            if conveyorBeltFeature.running || conveyorBeltFeature.conveyorBeltManager.GetPacketCount() > 0:
                canUseCheckFlag = false
    if canUseCheckFlag:
        var zombieList: Array = TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE)
        var zombieNum: int = zombieList.size()
        for zombie: TowerDefenseCharacter in zombieList:
            if zombie.config.name == "ZombieTarget":
                zombieNum -= 1
        if zombieNum > 0:
            return false
        return true
    return false

func Finish() -> void :
    if !levelControl:
        return
    if levelControl.awardCreate:
        return
    ViewManager.FullScreenColorBlink(Color.WHITE, 0.2, false)
    AudioManager.AudioPlay("WaveHuge", AudioManagerEnum.TYPE.SFX)
    var brainList = GetTree().get_nodes_in_group("Brain")
    if brainList.size() > 0:
        levelControl.awardPos = brainList[0].global_position
    levelControl.AwardCreate(levelControl.awardPos)

@warning_ignore("unused_parameter")
func PhysicsProcess(delta: float) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if !levelControl:
        return
    if CheckFinal():
        levelControl.AwardCreate(levelControl.awardPos)
    if CheckFail():
        if control:
            control.GameFail(null)

func SyncSerialize() -> Dictionary:
    var brain_count: int = GetTree().get_node_count_in_group("Brain")
    var brain_sun_count: int = GetTree().get_node_count_in_group("BrainSun")
    return {
        "brain_count": brain_count, 
        "brain_sun_count": brain_sun_count, 
        "sun": TowerDefenseManager.GetSun()
    }

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("sun"):
        TowerDefenseManager.SetSun(_data["sun"])

func SaveProcess() -> Dictionary:
    print("[Save] 保存Process[IZM]...")
    var result: Dictionary = {
        "sun": TowerDefenseManager.GetSun(), 
    }
    print("[Save] Process[IZM]保存完成: sun=%d" % result.sun)
    return result

func LoadProcess(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    print("[Load] 加载Process[IZM]... (数据项: %d)" % _data.size())
    TowerDefenseManager.SetSun(_data.get("sun", 50))
    print("[Load] Process[IZM]加载完成: sun=%d" % _data.get("sun", 50))
