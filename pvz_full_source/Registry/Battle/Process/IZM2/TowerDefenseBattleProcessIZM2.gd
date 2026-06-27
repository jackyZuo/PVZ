class_name TowerDefenseBattleProcessIZM2 extends TowerDefenseBattleProcess

var waveFeature: TowerDefenseBattleFeatureWave

var mapFeature: TowerDefenseBattleFeatureMap
var progressFeature: TowerDefenseBattleFeatureProgess
var cameraFeature: TowerDefenseBattleFeatureCamera
var seedBankFeature: TowerDefenseBattleFeatureSeedBank
var packetBankFeature: TowerDefenseBattleFeaturePacketBank
var mowerFeature: TowerDefenseBattleFeatureMower

var levelControl: TowerDefenseInGameLevelControl

func Init(_data: Dictionary) -> void :
    super.Init(_data)

func Ready() -> void :
    pass

func PhysicsProcess(delta: float) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if !levelControl.awardCreate:
        waveFeature.WavePhysicsProcess(delta)
        if levelControl.hasSpawn:
            levelControl.hasSpawn = false
            return
        if waveFeature.waveFinal && waveFeature.spawnOver:
            if CheckFinal():
                if !waveFeature.isSurvival:
                    levelControl.AwardCreate(levelControl.awardPos)
                elif waveFeature.survivalRunner.config.roundLimit == -1 || waveFeature.survivalRunner.config.roundLimit > waveFeature.survivalRunner.roundNum + 1:
                    if Global.enterLevelMode != "OnlineLevel" and !Global.isMultiplayerMode:
                        GameSaveManager.SaveLevelProgress(control.levelConfig.name)
                    waveFeature.survivalRunner.RoundReach(waveFeature.survivalRunner.roundNum + 1)
                    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                        MultiPlayerManager.SendGameEntry(waveFeature.survivalRunner.roundNum)
                    control.GameEntry()
                    levelControl.awardCreate = true
                else:
                    GameSaveManager.DeleteLevelProgress(control.levelConfig.name)
                    levelControl.AwardCreate(levelControl.awardPos)

@warning_ignore("unused_parameter")
func InputProcess(event: InputEvent) -> void :
    if CommandManager.debug && Input.is_action_just_pressed("DebugWaveNext"):
        waveFeature.NextWave()
    if control && control.isView:
        if Input.is_anything_pressed():
            control.viewBack.emit()

func GameInit() -> void :
    levelControl = control.levelControl

    waveFeature = GetFeature("Wave")
    mapFeature = GetFeature("Map")
    progressFeature = GetFeature("Progess")
    cameraFeature = GetFeature("Camera")
    seedBankFeature = GetFeature("SeedBank")
    packetBankFeature = GetFeature("PacketBank")
    mowerFeature = GetFeature("Mower")

func GameInitFromProgress() -> void :
    levelControl = control.levelControl

    waveFeature = GetFeature("Wave")
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
            control.uiTopAnimationPlayer.play("MobileEnter")
        else:
            control.uiTopAnimationPlayer.play("Enter")
        if packetBankFeature:
            packetBankFeature.packetBank.visible = false
        return
    if !control.isInit:
        var finalBroadCastConfig: BroadCastConfig = BroadCastConfig.new()
        finalBroadCastConfig.broadCastString = "更多的僵尸要来了！"
        BroadCastManager.BroadCastAdd(finalBroadCastConfig)
        await GetTree().create_timer(4.0, false).timeout
        if !is_instance_valid(control): return
        if GameSaveManager.GetConfigValue("MobilePreset"):
            control.uiTopAnimationPlayer.play("MobileExit")
        else:
            control.uiTopAnimationPlayer.play("Exit")
        for character in GetTree().get_nodes_in_group("Character"):
            character.process_mode = Node.PROCESS_MODE_DISABLED
        BroadCastManager.BraodCastClear()
        if seedBankFeature:
            seedBankFeature.seedBank.Prepare()
    if packetBankFeature:
        packetBankFeature.packetBank.visible = true
        levelControl.worldEntryLabel.visible = false
    waveFeature.Refresh()
    waveFeature.ShowCharacter()
    levelControl.worldEntryLabel.visible = true
    if waveFeature.isSurvival:
        levelControl.survivleLabel.text = "%d轮完成" % waveFeature.survivalRunner.roundNum
        levelControl.survivleLabel.visible = true
    GetTree().create_timer(2.0, false).timeout.connect(
        func():
            if is_instance_valid(levelControl):
                levelControl.worldEntryLabel.visible = false
                if is_instance_valid(GetLevelControl()) && waveFeature.isSurvival:
                    levelControl.survivleLabel.visible = false
    )
    var tween: Tween = cameraFeature.cameraControl.camera.create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(cameraFeature.cameraControl.camera, "global_position:x", cameraFeature.cameraControl.cameraRightViewMarker.global_position.x, 1.5)
    await tween.finished
    if !is_instance_valid(control): return
    if packetBankFeature && !packetBankFeature.skipPacketChoose:
        tween = cameraFeature.cameraControl.camera.create_tween()
        tween.set_ease(Tween.EASE_IN_OUT)
        tween.set_trans(Tween.TRANS_QUART)
        tween.tween_property(cameraFeature.cameraControl.camera, "global_position:x", cameraFeature.cameraControl.cameraPreViewMarker.global_position.x, 1.5)
        await tween.finished
        if !is_instance_valid(control): return
        control.buttonPause.visible = true
        if seedBankFeature:
            seedBankFeature.seedBank.packetSlotContainer.visible = true
        if GameSaveManager.GetConfigValue("MobilePreset"):
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileEnter")
            control.uiTopAnimationPlayer.play("MobileEnter")
        else:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Enter")
            control.uiTopAnimationPlayer.play("Enter")
        await packetBankFeature.chooseOver
        if !is_instance_valid(control): return
        if GameSaveManager.GetConfigValue("MobilePreset"):
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileExit")
        else:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Exit")
        if seedBankFeature:
            seedBankFeature.seedBank.Ready()
        await GetTree().create_timer(0.5, false).timeout
        if !is_instance_valid(control): return
    else:
        if seedBankFeature:
            seedBankFeature.seedBank.Ready()
        await GetTree().create_timer(0.5, false).timeout
        if !is_instance_valid(control): return
    tween = cameraFeature.cameraControl.camera.create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(cameraFeature.cameraControl.camera, "global_position:x", cameraFeature.cameraControl.cameraBeginMarker.global_position.x, 1.5)
    await tween.finished
    if !is_instance_valid(control): return
    if seedBankFeature:
        seedBankFeature.seedBank.packetSlotContainer.visible = true
    if packetBankFeature:
        if packetBankFeature.skipPacketChoose:
            if GameSaveManager.GetConfigValue("MobilePreset"):
                control.uiTopAnimationPlayer.play("MobileEnter")
            else:
                control.uiTopAnimationPlayer.play("Enter")
    else:
        if GameSaveManager.GetConfigValue("MobilePreset"):
            control.uiTopAnimationPlayer.play("MobileEnter")
        else:
            control.uiTopAnimationPlayer.play("Enter")
    if !control.isInit:
        waveFeature.SurvivalReady()
        for character in GetTree().get_nodes_in_group("Character"):
            character.process_mode = Node.PROCESS_MODE_INHERIT

func GameReady() -> void :
    if !control.hasProgress && data.get("MowerUse", false):
        if !waveFeature.isSurvival || control.isInit:
            mowerFeature.MowerInit()
    mowerFeature.IZM2Init()
    waveFeature.ClearShowCharacter()
    progressFeature.SetDifficultVisible(true)
    if waveFeature.isSurvival:
        progressFeature.SetSurvivalVisible(true)
    progressFeature.SetLevelNameVisible(true)
    if Global.enterLevelMode == "DailyLevel" || Global.enterLevelMode == "OnlineLevel" || Global.enterLevelMode == "LevelTest" || Global.enterLevelMode == "DiyLevel":
        progressFeature.SetDifficultVisible(false)
    if control.hasProgress:
        waveFeature.readySetPlantOver = true
        return

    if seedBankFeature:
        for packet: Node in seedBankFeature.seedBank.packetContainer.get_children():
            if packet is TowerDefenseInGamePacketShow:
                packet.onlyDraw = true
    await control.ReadySetPlantPlay()
    if !is_instance_valid(control): return
    waveFeature.readySetPlantOver = true

func GameStart() -> void :
    pass

func GameStartFromProgress() -> void :
    pass

@warning_ignore("unused_parameter")
func GameFail(enterCharacter: TowerDefenseCharacter) -> void :
    control.ZombieWonLevelFail(false)

func ZombieEnterHouse(character: TowerDefenseCharacter) -> void :
    if CommandManager.debug && CommandManager.debugNoLose:
        var tween = character.create_tween()
        tween.tween_property(character.sprite, "meshColor:a", 0.0, 1.0).finished.connect(
            func():
                if is_instance_valid(character):
                    character.Destroy()
        )
        return

func ViewMap() -> void :
    if packetBankFeature:
        if GameSaveManager.GetConfigValue("MobilePreset"):
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileExit")
        else:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Exit")
    if seedBankFeature:
        for packet: Node in seedBankFeature.seedBank.packetContainer.get_children():
            if packet is TowerDefenseInGamePacketShow:
                packet.onlyDraw = true
    var tween: Tween = cameraFeature.cameraControl.camera.create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(cameraFeature.cameraControl.camera, "global_position:x", cameraFeature.cameraControl.cameraBeginMarker.global_position.x, 1.5)
    control.isView = true
    await tween.finished
    if !is_instance_valid(control): return
    var broadCastConfig: BroadCastConfig = BroadCastConfig.new()
    broadCastConfig.broadCastString = "INGAME_VIEW_BACK"
    BroadCastManager.BroadCastAdd(broadCastConfig)
    await control.viewBack
    if !is_instance_valid(control): return
    BroadCastManager.BraodCastClear()
    control.isView = false
    if seedBankFeature:
        for packet: Node in seedBankFeature.seedBank.packetContainer.get_children():
            if packet is TowerDefenseInGamePacketShow:
                packet.onlyDraw = false
    tween = cameraFeature.cameraControl.camera.create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(cameraFeature.cameraControl.camera, "global_position:x", cameraFeature.cameraControl.cameraPreViewMarker.global_position.x, 1.5)
    await tween.finished
    if !is_instance_valid(control): return
    if packetBankFeature:
        if GameSaveManager.GetConfigValue("MobilePreset"):
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("MobileEnter")
        else:
            packetBankFeature.packetBank.packetBankAnimationPlayer.play("Enter")

func CheckFinal() -> bool:
    var vaseList: Array = GetTree().get_nodes_in_group("Vase")
    if vaseList.size() > 0:
        return false
    var targetList: Array = TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE)
    var targetNum: int = targetList.size()
    for target: TowerDefenseCharacter in targetList:
        if target is TowerDefensePlant:
            if target.config.izm2Fliter:
                targetNum -= 1
        if target.instance.die == true:
            targetNum -= 1
    if targetNum > 0:
        levelControl.awardPos = targetList[0].global_position
    if targetNum == 0:
        for target: TowerDefenseCharacter in TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.PLANT):
            target.Hurt(1000000000000)
    return targetNum <= 0

func Finish() -> void :
    if levelControl.awardCreate:
        return
    ViewManager.FullScreenColorBlink(Color.WHITE, 0.2, false)
    AudioManager.AudioPlay("WaveHuge", AudioManagerEnum.TYPE.SFX)
    var targetList: Array = TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.PLANT)
    var targetNum: int = targetList.size()
    if targetNum > 0:
        levelControl.awardPos = targetList[0].global_position
    for target: TowerDefenseCharacter in targetList:
        target.Destroy()
    levelControl.AwardCreate(levelControl.awardPos)

func SyncSerialize() -> Dictionary:
    return waveFeature.SyncSerialize()

func SyncDeserialize(_data: Dictionary) -> void :
    waveFeature.SyncDeserialize(_data)

func SaveProcess() -> Dictionary:
    return waveFeature.SaveFeature()

func LoadProcess(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    waveFeature.LoadFeature(_data, _owner)
