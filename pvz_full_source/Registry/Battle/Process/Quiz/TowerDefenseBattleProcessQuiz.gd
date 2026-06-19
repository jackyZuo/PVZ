class_name TowerDefenseBattleProcessQuiz extends TowerDefenseBattleProcess

const QUIZ_CONTROL = preload("uid://dlywvjp6hpbgu")
const CHANGE_PRESENT_BOX_BUTTON = preload("uid://bjtvgkckq2ft5")
const BET_PANEL = preload("uid://knp6uvl6ja3d")

var stripPos: int = 5
var running: bool = false
var vaseList: Array[TowerDefenseCharacter] = []
var multiple: int = 1
var over: bool = false
var useCoin: int = 0

var quizStarted: bool = false

var quizUI: QuizControl

var sunFeature: TowerDefenseBattleFeatureSun
var mapFeature: TowerDefenseBattleFeatureMap
var progressFeature: TowerDefenseBattleFeatureProgess
var cameraFeature: TowerDefenseBattleFeatureCamera
var seedBankFeature: TowerDefenseBattleFeatureSeedBank
var packetBankFeature: TowerDefenseBattleFeaturePacketBank
var brainFeature: TowerDefenseBattleFeatureBrain

var levelControl: TowerDefenseInGameLevelControl

func CanLoadProgress() -> bool:
    return false

func Ready() -> void :
    pass

func SetupUI() -> void :
    await GetTree().physics_frame
    var text = tr(TowerDefenseManager.currentLevelConfig.levelName).replace("{LevelNumber}", str(TowerDefenseManager.currentLevelConfig.levelNumber))
    progressFeature.SetLevelName(text)
    progressFeature.SetDifficultVisible(false)

func GameInit() -> void :
    CreateUI()
    SetupUI()

func GameInitFromProgress() -> void :
    CreateUI()
    SetupUI()

func CreateUI() -> void :
    quizUI = QUIZ_CONTROL.instantiate()
    control.AddUI(quizUI, 4)
    if !quizUI.run_button_pressed.is_connected(RunButtonPressed):
        quizUI.run_button_pressed.connect(RunButtonPressed)
    TowerDefenseManager.coinBank.Show(Vector2(250, 557), true)
    quizUI.visible = true
    quizUI.startGUINode.visible = true
    var gridNum = mapFeature.config.gridNum
    for y in range(1, gridNum.y + 1, 1):
        var button = CHANGE_PRESENT_BOX_BUTTON.instantiate() as MainButton
        button.global_position = Vector2(TowerDefenseManager.GetMapGroundRight(), TowerDefenseManager.GetMapCellPos(Vector2(0, y)).y + 20)
        quizUI.changePresentBoxButtonNode.add_child(button)
        button.pressed.connect(ChangePresentBoxButtonPressed.bind(y, button))
        var bet = BET_PANEL.instantiate()
        bet.global_position = Vector2(0, TowerDefenseManager.GetMapCellPos(Vector2(0, y)).y + 30)
        quizUI.betPanelNode.add_child(bet)
        bet.Init(y)

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    levelControl = control.levelControl

    sunFeature = GetFeature("Sun")
    mapFeature = GetFeature("Map")
    progressFeature = GetFeature("Progess")
    cameraFeature = GetFeature("Camera")
    seedBankFeature = GetFeature("SeedBank")
    packetBankFeature = GetFeature("PacketBank")
    brainFeature = GetFeature("Brain")

func StartQuiz() -> void :
    if quizStarted:
        return
    quizStarted = true
    var gridNum = mapFeature.config.gridNum
    stripPos = floor(gridNum.x / 2) + 1
    mapFeature.currentMap.UseStripe(stripPos)
    if brainFeature:
        brainFeature.BrainInit()
    var gridPos: Vector2i
    for x in range(1, gridNum.x + 1, 1):
        for y in range(1, gridNum.y + 1, 1):
            gridPos = Vector2i(x, y)
            if x <= stripPos:
                CreatePresentBox(gridPos)
            else:
                CreateZombieVase(gridPos)

func Refresh() -> void :
    if !quizUI:
        return
    TowerDefenseManager.currentControl.isGameRunning = false
    useCoin = 0
    running = false
    over = false
    multiple = 1
    quizStarted = false
    quizUI.coinLabel.text = "金币倍数：%d倍" % multiple
    vaseList.clear()
    var gridNum = mapFeature.config.gridNum
    stripPos = floor(gridNum.x / 2) + 1
    var gridPos: Vector2i
    for x in range(1, gridNum.x + 1, 1):
        for y in range(1, gridNum.y + 1, 1):
            gridPos = Vector2i(x, y)
            ClearCell(gridPos)
    for projectile in GetTree().get_nodes_in_group("Projectile"):
        projectile.queue_free()
    for character in TowerDefenseManager.GetCharacter():
        character.skipDestroySet = true
        TowerDefenseManager.CharacterUnregister(character)
        character.remove_from_group("Character")
        character.queue_free()
    for iceCap in mapFeature.iceCapList:
        if is_instance_valid(iceCap):
            iceCap.queue_free()
    for brain in GetTree().get_nodes_in_group("Brain"):
        brain.queue_free()
    for node in quizUI.betPanelNode.get_children():
        node.queue_free()
    for node in quizUI.changePresentBoxButtonNode.get_children():
        node.queue_free()
    quizUI.queue_free()
    quizUI = null
    await GetTree().physics_frame
    CreateUI()
    StartQuiz()

func ClearCell(gridPos: Vector2i) -> void :
    var cell = TowerDefenseManager.GetMapCell(gridPos)
    for character: TowerDefenseCharacter in cell.characterList.duplicate():
        character.skipDestroySet = true
    cell.Clear()
    await GetTree().physics_frame

func CreatePresentBox(gridPos: Vector2i, open: bool = true) -> void :
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    if is_instance_valid(cell):
        if cell.gridType.has(TowerDefenseEnum.PLANTGRIDTYPE.BRICK) || cell.gridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SOIL):
            var potPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPot")
            potPacket.Plant(gridPos)
        if cell.gridType.has(TowerDefenseEnum.PLANTGRIDTYPE.WATER):
            var lilyPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantLilyPad")
            lilyPacket.Plant(gridPos)
    var presentBoxPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPresentBox")
    var presentBox = presentBoxPacket.Plant(gridPos, true)
    presentBox.add_to_group("PresentBox")
    presentBox.process_mode = Node.PROCESS_MODE_DISABLED
    if !presentBox:
        return
    presentBox.packetBank = "PresentBoxNoAshPlant"
    if open:
        await GetTree().physics_frame
        presentBox.process_mode = Node.PROCESS_MODE_INHERIT
        presentBox.instance.invincible = true
        presentBox.sprite.SetAnimation("Open", false)

func CreateZombieVase(gridPos: Vector2i) -> void :
    var zombieVasePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("VaseZombie")
    var zombieVase = zombieVasePacket.Plant(gridPos, true)
    if !zombieVase:
        return
    zombieVase.state.process_mode = Node.PROCESS_MODE_INHERIT
    zombieVase.packetBank = "QuizZombie"
    vaseList.append(zombieVase)

func ChangePresentBox(line: int) -> void :
    var gridPos: Vector2i
    for x in range(1, stripPos + 1, 1):
        gridPos = Vector2i(x, line)
        var cell = TowerDefenseManager.GetMapCell(gridPos)
        for character: TowerDefenseCharacter in cell.characterList.duplicate():
            character.skipDestroySet = true
        cell.Clear()
        await GetTree().physics_frame
        CreatePresentBox(gridPos, false)

func ChangePresentBoxButtonPressed(line: int, button: MainButton) -> void :
    if !quizUI:
        return
    var needCoin = 0
    for betPanel in quizUI.betPanelNode.get_children():
        needCoin += betPanel.betCoinSpinBox.value
    if TowerDefenseManager.GetCoin() < needCoin * (multiple + 2):
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]您的金币不足[/font_size][/center]\n[center][font_size=24]至少需要%d金币[/font_size][/center]" % (needCoin * (multiple + 2))
        return
    ChangePresentBox(line)
    button.queue_free()
    multiple += 1
    quizUI.coinLabel.text = "金币倍数：%d倍" % multiple

func RunButtonPressed() -> void :
    if !quizUI:
        return
    var needCoin = 0
    for betPanel in quizUI.betPanelNode.get_children():
        needCoin += betPanel.betCoinSpinBox.value
    if TowerDefenseManager.GetCoin() < (needCoin * (multiple + 1)):
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]您的金币不足[/font_size][/center]\n[center][font_size=24]至少需要%d金币[/font_size][/center]" % (needCoin * (multiple + 1))
        return
    var chooseDialog = DialogManager.DialogCreate("DialogBoxChoose")
    chooseDialog.text = "[center][font_size=24]是否使用%d金币入场[/font_size][/center]" % (needCoin * multiple)
    chooseDialog.chooseTrue.connect(
        func():
            Run(needCoin * multiple)
    )

func Run(needCoin: int) -> void :
    if !quizUI:
        return
    useCoin = needCoin
    TowerDefenseManager.UseCoin(useCoin)
    running = true
    quizUI.startGUINode.visible = false
    TowerDefenseManager.currentControl.isGameRunning = true
    for vase in vaseList:
        vase.Destroy()
    for betPanel in quizUI.betPanelNode.get_children():
        betPanel.Finish()
    for character in TowerDefenseManager.GetCharacter():
        character.state.process_mode = Node.PROCESS_MODE_INHERIT
        character.call("Idle")
    for presentBox in GetTree().get_nodes_in_group("PresentBox"):
        presentBox.process_mode = Node.PROCESS_MODE_INHERIT
    GameSaveManager.Save()

func CheckFinal() -> bool:
    if TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.PLANT).size() <= 0:
        if GetTree().get_node_count_in_group("Vase") > 0:
            for vase in GetTree().get_nodes_in_group("Vase"):
                vase.Destroy()
            return false
        return true
    if CheckFail():
        return true
    return false

func CheckFail() -> bool:
    if GetTree().get_node_count_in_group("Vase") > 0:
        return false
    var zombieList = TowerDefenseManager.GetCampTarget(TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE)
    for zombie in zombieList:
        if !zombie.instance.die && !zombie.instance.nearDie:
            return false
    return true

func Final() -> void :
    if over:
        return
    over = true
    if !quizUI:
        return
    TowerDefenseManager.currentControl.checkBox2X.button_pressed = false
    running = false
    var coinNum: int = 0
    var gridNum = mapFeature.config.gridNum
    var zombieWinLine = []
    zombieWinLine.resize(gridNum.y + 1)
    zombieWinLine.fill(true)
    var brainList = GetTree().get_nodes_in_group("Brain")
    for brain in brainList:
        zombieWinLine[brain.gridPos.y] = false
    var numText = ""
    for y in range(1, gridNum.y + 1, 1):
        var isTrue: bool = false
        var skip: bool = false
        var betPanel = quizUI.betPanelNode.get_child(y - 1)
        var coin: int = betPanel.betCoinSpinBox.value
        match betPanel.chooseLabel.text:
            "赢":
                if zombieWinLine[y]:
                    isTrue = true
            "输":
                if !zombieWinLine[y]:
                    isTrue = true
            "跳":
                skip = true
        BroadCastManager.BraodCastClear()
        var broadCastConfig: BroadCastConfig = BroadCastConfig.new()
        if skip:
            broadCastConfig.broadCastString = "第%d行:不结算" % [y]
        else:
            if isTrue:
                broadCastConfig.broadCastString = "第%d行:判断成功 结算:%d金币" % [y, coin]
                if y == 1:
                    numText += "%d" % coin
                else:
                    numText += "+%d" % coin
                coinNum += coin * (multiple + 1)
            else:
                broadCastConfig.broadCastString = "第%d行:判断失败 结算:-%d金币" % [y, coin]
                if y == 1:
                    numText += "-%d" % coin
                else:
                    numText += "-%d" % coin
                coinNum -= coin * (multiple + 1)
        BroadCastManager.BroadCastAdd(broadCastConfig)
        await GetTree().create_timer(1.0, false).timeout
    BroadCastManager.BraodCastClear()
    var finalBroadCastConfig: BroadCastConfig = BroadCastConfig.new()
    if coinNum > 0:
        finalBroadCastConfig.broadCastString = "总结算:(%s)x%d=%d\n获得%d金币\n返还%d金币" % [numText, multiple + 1, coinNum, coinNum, useCoin]
    elif coinNum < 0:
        if coinNum + useCoin > 0:
            finalBroadCastConfig.broadCastString = "总结算:(%s)x%d=%d\n返还%d金币" % [numText, multiple + 1, coinNum, coinNum + useCoin]
        else:
            finalBroadCastConfig.broadCastString = "总结算:(%s)x%d=%d\n扣除%d金币" % [numText, multiple + 1, coinNum, abs(coinNum + useCoin)]
    BroadCastManager.BroadCastAdd(finalBroadCastConfig)
    if coinNum > 0:
        await CreateCoin(coinNum + useCoin)
    elif coinNum < 0:
        if coinNum + useCoin > 0:
            await CreateCoin(coinNum + useCoin)
        else:
            TowerDefenseManager.UseCoin(abs(coinNum + useCoin))
    await GetTree().create_timer(2.0, false).timeout
    BroadCastManager.BraodCastClear()
    ViewManager.FullScreenColorBlink(Color.WHITE, 0.2, false)
    AudioManager.AudioPlay("WaveHuge", AudioManagerEnum.TYPE.SFX)
    Refresh()
    GameSaveManager.Save()

func CreateCoin(num: int) -> void :
    if !quizUI:
        return
    var gridNum = mapFeature.config.gridNum
    while num >= 1000:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_DIAMOND, TowerDefenseManager.GetMapCellPosCenter(Vector2i(randi_range(1, gridNum.x), randi_range(1, gridNum.y))), 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.canMagnet = false
        item.gridPos.y = 200
        item.reparent(quizUI, false)
        GetTree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        GetTree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 1000
        await GetTree().create_timer(0.1, false).timeout
    while num >= 50:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, TowerDefenseManager.GetMapCellPosCenter(Vector2i(randi_range(1, gridNum.x), randi_range(1, gridNum.y))), 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.canMagnet = false
        item.gridPos.y = 200
        item.reparent(quizUI, false)
        GetTree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        GetTree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 50
        await GetTree().create_timer(0.1, false).timeout
    while num >= 10:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, TowerDefenseManager.GetMapCellPosCenter(Vector2i(randi_range(1, gridNum.x), randi_range(1, gridNum.y))), 30, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.canMagnet = false
        item.gridPos.y = 200
        item.reparent(quizUI, false)
        GetTree().create_timer(1.0, false).timeout.connect(item.moveComponent.MoveClear)
        GetTree().create_timer(1.5, false).timeout.connect(item.Collection)
        num -= 10
        await GetTree().create_timer(0.1, false).timeout

func GameEntry() -> void :
    GameReady()

func GameReady() -> void :
    if progressFeature:
        progressFeature.SetProgressMeterMaxValue(GetTree().get_node_count_in_group("Brain"))
        progressFeature.SetProgressMeterWaveNum(GetTree().get_node_count_in_group("Brain"))
        progressFeature.SetProgressMeterPreviewWave(0)
        progressFeature.SetProgressMeterValue(0)
        progressFeature.SetLevelNameVisible(true)
        if Global.enterLevelMode == "DailyLevel" || Global.enterLevelMode == "OnlineLevel" || Global.enterLevelMode == "LevelTest" || Global.enterLevelMode == "DiyLevel":
            progressFeature.SetDifficultVisible(false)

func GameStart() -> void :
    StartQuiz()

func GameStartFromProgress() -> void :
    StartQuiz()

@warning_ignore("unused_parameter")
func GameFail(enterCharacter: TowerDefenseCharacter) -> void :
    pass

func ZombieEnterHouse(character: TowerDefenseCharacter) -> void :
    character.Destroy()

func Finish() -> void :
    pass

func SaveProcess() -> Dictionary:
    print("[Save] 保存Process[Quiz]...")
    var result: Dictionary = {
        "stripPos": stripPos, 
        "running": running, 
        "multiple": multiple, 
        "over": over, 
        "useCoin": useCoin, 
    }
    print("[Save] Process[Quiz]保存完成: stripPos=%d, running=%s, multiple=%d, over=%s, useCoin=%d" % [stripPos, running, multiple, over, useCoin])
    return result

func LoadProcess(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    print("[Load] 加载Process[Quiz]... (数据项: %d)" % _data.size())
    stripPos = _data.get("stripPos", 5)
    running = _data.get("running", false)
    multiple = _data.get("multiple", 1)
    over = _data.get("over", false)
    useCoin = _data.get("useCoin", 0)
    print("[Load] Process[Quiz]加载完成: stripPos=%d, running=%s, multiple=%d, over=%s, useCoin=%d" % [stripPos, running, multiple, over, useCoin])

@warning_ignore("unused_parameter")
func PhysicsProcess(delta: float) -> void :
    if !running:
        return
    if CheckFinal():
        Final()
