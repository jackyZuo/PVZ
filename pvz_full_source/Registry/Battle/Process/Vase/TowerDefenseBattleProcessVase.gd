class_name TowerDefenseBattleProcessVase extends TowerDefenseBattleProcess

var config: TowerDefenseLevelVaseManagerConfig

var sunFeature: TowerDefenseBattleFeatureSun
var mapFeature: TowerDefenseBattleFeatureMap
var progressFeature: TowerDefenseBattleFeatureProgess
var cameraFeature: TowerDefenseBattleFeatureCamera
var seedBankFeature: TowerDefenseBattleFeatureSeedBank
var packetBankFeature: TowerDefenseBattleFeaturePacketBank
var mowerFeature: TowerDefenseBattleFeatureMower

var levelControl: TowerDefenseInGameLevelControl

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelVaseManagerConfig.new()
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
    mowerFeature = GetFeature("Mower")

    SetupUI()

    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return

    if !config.shuffle:
        for vaseConfig: TowerDefenseLevelVaseConfig in config.vaseList:
            var vasePacketConfig: TowerDefensePacketConfig
            match vaseConfig.type:
                "Plant":
                    vasePacketConfig = TowerDefenseManager.GetPacketConfig("VasePlant")
                "Zombie":
                    vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseZombie")
                _:
                    vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseNormal")
            var vase = vasePacketConfig.Plant(vaseConfig.gridPos)
            if is_instance_valid(vase):
                if vaseConfig.packetName != "":
                    vase.packetConfig = vaseConfig.GetPacket()
                else:
                    if config.vaseFillList.size() > 0:
                        var packetConfig = config.vaseFillList.pick_random().GetPacket()
                        while (true):
                            if vaseConfig.type != "Plant" && vaseConfig.type != "Zombieal":
                                break
                            if vaseConfig.type == "Plant" && packetConfig.characterConfig is TowerDefensePlantConfig:
                                break
                            if vaseConfig.type == "Zombie" && packetConfig.characterConfig is TowerDefenseZombieConfig:
                                break
                            packetConfig = config.vaseFillList.pick_random().GetPacket()
                        vase.packetConfig = packetConfig
    else:
        var posList: Array[Vector2i] = []
        var typeList: Array[String] = []
        var packetConfigList: Array[TowerDefensePacketConfig]
        for vaseConfig: TowerDefenseLevelVaseConfig in config.vaseList:
            posList.append(vaseConfig.gridPos)
            typeList.append(vaseConfig.type)
            if vaseConfig.packetName == "":
                if config.vaseFillList.size() > 0:
                    packetConfigList.append(config.vaseFillList.pick_random().GetPacket())
                else:
                    packetConfigList.append(null)
            else:
                packetConfigList.append(vaseConfig.GetPacket())
        posList.shuffle()
        typeList.shuffle()
        packetConfigList.shuffle()
        for packetConfig: TowerDefensePacketConfig in packetConfigList:
            var pos: Vector2 = posList.pop_back()
            var type: String = "Normal"
            if is_instance_valid(packetConfig):
                if packetConfig.characterConfig is TowerDefensePlantConfig:
                    if typeList.has("Plant"):
                        type = "Plant"
                        typeList.erase("Plant")
                elif packetConfig.characterConfig is TowerDefenseZombieConfig:
                    if typeList.has("Zombie"):
                        type = "Zombie"
                        typeList.erase("Zombie")
                else:
                    type = typeList.pop_back()
            else:
                type = typeList.pop_back()
            var vasePacketConfig: TowerDefensePacketConfig
            match type:
                "Plant":
                    vasePacketConfig = TowerDefenseManager.GetPacketConfig("VasePlant")
                "Zombie":
                    vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseZombie")
                _:
                    vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseNormal")
            var vase = vasePacketConfig.Plant(pos)
            vase.packetConfig = packetConfig

func GameInitFromProgress() -> void :
    levelControl = control.levelControl

    sunFeature = GetFeature("Sun")
    mapFeature = GetFeature("Map")
    progressFeature = GetFeature("Progess")
    cameraFeature = GetFeature("Camera")
    seedBankFeature = GetFeature("SeedBank")
    packetBankFeature = GetFeature("PacketBank")
    mowerFeature = GetFeature("Mower")

func GameEntry() -> void :
    if control.hasProgress:
        if seedBankFeature:
            seedBankFeature.seedBank.packetSlotContainer.visible = true
            if GameSaveManager.GetConfigValue("MobilePreset"):
                seedBankFeature.seedBank.animationPlayer.play("MobileEnter")
            else:
                seedBankFeature.seedBank.animationPlayer.play("Enter")
        if GameSaveManager.GetConfigValue("MobilePreset"):
            control.uiTopAnimationPlayer.play("MobileEnter")
        else:
            control.uiTopAnimationPlayer.play("Enter")
        return
    match data.get("PacketBankMethod", 0):
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE, TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET, TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
            if packetBankFeature and !packetBankFeature.skipPacketChoose:
                if GameSaveManager.GetConfigValue("MobilePreset"):
                    packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileEnter")
                    seedBankFeature.seedBank.animationPlayer.play("MobileEnter")
                else:
                    packetBankFeature.packetBank.packetBankAnimationPlayer.play("Enter")
                    seedBankFeature.seedBank.animationPlayer.play("Enter")
                control.buttonPause.visible = true
                seedBankFeature.seedBank.packetSlotContainer.visible = true
                await packetBankFeature.chooseOver
                seedBankFeature.seedBank.Ready()
                if GameSaveManager.GetConfigValue("MobilePreset"):
                    packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileExit")
                else:
                    packetBankFeature.packetBank.packetBankAnimationPlayer.play("Exit")
                await GetTree().create_timer(0.5, false).timeout
                if GameSaveManager.GetConfigValue("MobilePreset"):
                    control.uiTopAnimationPlayer.play("MobileEnter")
                else:
                    control.uiTopAnimationPlayer.play("Enter")
            else:
                if seedBankFeature:
                    seedBankFeature.seedBank.Ready()
                if GameSaveManager.GetConfigValue("MobilePreset"):
                    seedBankFeature.seedBank.animationPlayer.play("MobileEnter")
                else:
                    seedBankFeature.seedBank.animationPlayer.play("Enter")
        _:
            if GameSaveManager.GetConfigValue("MobilePreset"):
                control.uiTopAnimationPlayer.play("MobileEnter")
            else:
                control.uiTopAnimationPlayer.play("Enter")
    GameReady()
    GameStart()

func GameReady() -> void :
    if !control.hasProgress && data.get("MowerUse", false):
        if mowerFeature:
            mowerFeature.MowerInit()
    if progressFeature:
        progressFeature.SetLevelNameVisible(true)
        if Global.enterLevelMode == "DailyLevel" || Global.enterLevelMode == "OnlineLevel" || Global.enterLevelMode == "LevelTest" || Global.enterLevelMode == "DiyLevel":
            progressFeature.SetDifficultVisible(false)

func GameStart() -> void :
    pass

func GameFail(enterCharacter: TowerDefenseCharacter) -> void :
    for character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
        if character != enterCharacter:
            character.process_mode = Node.PROCESS_MODE_DISABLED
    if packetBankFeature and packetBankFeature.packetBank:
        packetBankFeature.packetBank.visible = false
    control.bankUILayer.visible = false
    if mapFeature && is_instance_valid(mapFeature.currentMap):
        await mapFeature.currentMap.EnterRoom(enterCharacter)
    if is_instance_valid(enterCharacter):
        enterCharacter.process_mode = Node.PROCESS_MODE_DISABLED
    control.ZombieWonLevelFail()

func ZombieEnterHouse(character: TowerDefenseCharacter) -> void :
    if CommandManager.debug && CommandManager.debugNoLose:
        var tween = character.create_tween()
        tween.tween_property(character.sprite, "meshColor:a", 0.0, 1.0).finished.connect(
            func():
                if is_instance_valid(character):
                    character.Destroy()
        )
        return
    if control:
        control.GameFail(character)

func ViewMap() -> void :
    if GameSaveManager.GetConfigValue("MobilePreset"):
        if packetBankFeature and packetBankFeature.packetBank:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileExit")
    else:
        if packetBankFeature and packetBankFeature.packetBank:
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
        if packetBankFeature and packetBankFeature.packetBank:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileEnter")
    else:
        if packetBankFeature and packetBankFeature.packetBank:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Enter")

@warning_ignore("unused_parameter")
func InputProcess(event: InputEvent) -> void :
    if control && control.isView:
        if Input.is_anything_pressed():
            control.viewBack.emit()

func CheckFinal() -> bool:
    if !levelControl:
        return false
    var vaseList: Array = GetTree().get_nodes_in_group("Vase")
    if vaseList.size() > 0:
        return false
    var targetList: Array = TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.PLANT)
    var targetNum: int = targetList.size()
    for target: TowerDefenseCharacter in targetList:
        if target.instance.die == true:
            targetNum -= 1
        if target.config.name.begins_with("ZombieDigger") || \
target.config.name.begins_with("ZombieYetiDigger"):
            targetNum -= 1
        elif target.scale.x < 0:
            targetNum -= 1
    if targetNum == 0:
        var zombieList: Array = GetTree().get_nodes_in_group("Zombie")
        for zombie: TowerDefenseCharacter in zombieList:
            if zombie.isDestroy && !zombie.skipDestroySet:
                return false
    if targetNum > 0:
        levelControl.awardPos = targetList[0].global_position
    if targetNum == 0:
        for target: TowerDefenseCharacter in targetList:
            target.Destroy()
    return targetNum <= 0

func Finish() -> void :
    if !levelControl:
        return
    if levelControl.awardCreate:
        return
    ViewManager.FullScreenColorBlink(Color.WHITE, 0.2, false)
    AudioManager.AudioPlay("WaveHuge", AudioManagerEnum.TYPE.SFX)
    var targetList: Array = TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.PLANT)
    if targetList.size() > 0:
        levelControl.awardPos = targetList[0].global_position
    for target: TowerDefenseCharacter in targetList:
        target.Destroy()
    levelControl.AwardCreate(levelControl.awardPos)

@warning_ignore("unused_parameter")
func PhysicsProcess(delta: float) -> void :
    if !levelControl:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if CheckFinal():
        levelControl.AwardCreate(levelControl.awardPos)

func SyncSerialize() -> Dictionary:
    var vase_list: Array = []
    for vase in GetTree().get_nodes_in_group("Vase"):
        if is_instance_valid(vase) and !vase.over:
            var vase_export: TowerDefenseLevelVaseConfig = vase.Export()
            vase_list.append({
                "grid_x": vase.gridPos.x, 
                "grid_y": vase.gridPos.y, 
                "type": vase_export.type, 
                "content_name": vase_export.packetName
            })
    return {"vases": vase_list}

func SyncDeserialize(_data: Dictionary) -> void :
    if !_data.has("vases"):
        return
    var synced_positions: Dictionary = {}
    for vaseData: Dictionary in _data["vases"]:
        var gridX: int = vaseData.get("grid_x", 0)
        var gridY: int = vaseData.get("grid_y", 0)
        synced_positions[str(gridX) + "_" + str(gridY)] = vaseData
    for vase in GetTree().get_nodes_in_group("Vase"):
        if !is_instance_valid(vase) or vase.over:
            continue
        var key: String = str(vase.gridPos.x) + "_" + str(vase.gridPos.y)
        if !synced_positions.has(key):
            vase.queue_free()
    var existing_positions: Dictionary = {}
    for vase in GetTree().get_nodes_in_group("Vase"):
        if is_instance_valid(vase):
            existing_positions[str(vase.gridPos.x) + "_" + str(vase.gridPos.y)] = true
    for key in synced_positions:
        if existing_positions.has(key):
            continue
        var vaseData: Dictionary = synced_positions[key]
        var gridX: int = vaseData.get("grid_x", 0)
        var gridY: int = vaseData.get("grid_y", 0)
        var vaseType: String = vaseData.get("type", "Normal")
        var contentName: String = vaseData.get("content_name", "")
        var vasePacketConfig: TowerDefensePacketConfig
        match vaseType:
            "Plant":
                vasePacketConfig = TowerDefenseManager.GetPacketConfig("VasePlant")
            "Zombie":
                vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseZombie")
            _:
                vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseNormal")
        var vase = vasePacketConfig.Plant(Vector2i(gridX, gridY))
        if is_instance_valid(vase) and contentName != "":
            vase.packetName = contentName

func SaveProcess() -> Dictionary:
    print("[Save] 保存Process[Vase]...")
    var vaseDataList: Array = []
    for vase: TowerDefenseCharacter in GetTree().get_nodes_in_group("Vase"):
        if !is_instance_valid(vase):
            continue
        var contentName: String = ""
        if is_instance_valid(vase.packetConfig):
            contentName = vase.packetConfig.saveKey
        vaseDataList.append({
            "nodeName": vase.name.validate_node_name(), 
            "gridPosX": vase.gridPos.x, 
            "gridPosY": vase.gridPos.y, 
            "contentName": contentName, 
        })
    var packetShowDataList: Array = []
    for packetShow: TowerDefenseInGamePacketShow in GetTree().get_nodes_in_group("VasePacketShow"):
        if !is_instance_valid(packetShow) || !is_instance_valid(packetShow.config):
            continue
        var moveData: Dictionary = {}
        if is_instance_valid(packetShow.moveComponent):
            moveData = packetShow.moveComponent.ExportComponentSave()
        packetShowDataList.append({
            "saveKey": packetShow.config.saveKey, 
            "posX": packetShow.global_position.x, 
            "posY": packetShow.global_position.y, 
            "zIndex": packetShow.z_index, 
            "aliveTime": packetShow.aliveTime, 
            "aliveTimer": packetShow.aliveTimer, 
            "blinkTimer": packetShow.blinkTimer, 
            "blink": packetShow.blink, 
            "height": packetShow.height, 
            "savePosX": packetShow.savePos.x, 
            "savePosY": packetShow.savePos.y, 
            "moveData": moveData, 
        })
    var result: Dictionary = {
        "vaseList": vaseDataList, 
        "packetShowList": packetShowDataList, 
    }
    print("[Save] Process[Vase]保存完成: vaseList=%d, packetShowList=%d" % [vaseDataList.size(), packetShowDataList.size()])
    return result

func LoadProcess(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    print("[Load] 加载Process[Vase]... (数据项: %d)" % _data.size())
    for vaseData: Dictionary in _data.get("vaseList", []):
        var nodeName: StringName = vaseData.get("nodeName", "")
        var vase: TowerDefenseCharacter = _owner.charcterDicionary.get(nodeName) if _owner.charcterDicionary.has(nodeName) else null
        if is_instance_valid(vase) and is_instance_valid(vase.vaseContentComponent):
            var contentName: String = vaseData.get("contentName", "")
            if contentName != "":
                vase.vaseContentComponent.SetContent(contentName)
    for packetShowData: Dictionary in _data.get("packetShowList", []):
        var saveKey: String = packetShowData.get("saveKey", "")
        if saveKey == "":
            continue
        var packetInstance: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
        packetInstance.z_index = packetShowData.get("zIndex", 0)
        packetInstance.global_position = Vector2(packetShowData.get("posX", 0.0), packetShowData.get("posY", 0.0))
        TowerDefenseGroundItemBase.characterNode.add_child(packetInstance)
        packetInstance.Init(TowerDefenseManager.GetPacketConfig(saveKey))
        packetInstance.onlyDraw = false
        packetInstance.showCost = false
        packetInstance.useCost = false
        packetInstance.plantOnce = true
        packetInstance.canPressPutBack = false
        packetInstance.StartInit()
        packetInstance.alive = true
        packetInstance.aliveTime = packetShowData.get("aliveTime", 15.0)
        packetInstance.aliveTimer = packetShowData.get("aliveTimer", 0.0)
        packetInstance.blinkTimer = packetShowData.get("blinkTimer", 0.0)
        packetInstance.blink = packetShowData.get("blink", false)
        packetInstance.height = packetShowData.get("height", -1)
        packetInstance.savePos = Vector2(packetShowData.get("savePosX", 0.0), packetShowData.get("savePosY", 0.0))
        var moveData: Dictionary = packetShowData.get("moveData", {})
        if !moveData.is_empty() && is_instance_valid(packetInstance.moveComponent):
            packetInstance.moveComponent.ImportComponentSave(moveData, _owner)
        elif moveData.is_empty() && is_instance_valid(packetInstance.moveComponent):
            packetInstance.moveComponent.queue_free()
        var packetPickControl: PacketPickControl = TowerDefenseManager.GetPacketPickControl()
        if is_instance_valid(packetPickControl):
            packetInstance.pressed.connect(packetPickControl.PickPacket)
        packetInstance.add_to_group("VasePacketShow")
    print("[Load] Process[Vase]加载完成: vaseList=%d, packetShowList=%d" % [_data.get("vaseList", []).size(), _data.get("packetShowList", []).size()])
