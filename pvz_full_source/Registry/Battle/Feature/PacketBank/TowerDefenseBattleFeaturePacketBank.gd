class_name TowerDefenseBattleFeaturePacketBank extends TowerDefenseBattleFeature

const TOWER_DEFENSE_INGAME_PACKET_BANK = preload("uid://iydc3rp06xgs")

const BATCH_SIZE: int = 8
const MAX_POOL_SIZE: int = 200

signal chooseOver()

var packetBank: TowerDefenseInGamePacketBank
var config: TowerDefenseLevelPacketBankConfig
var skipPacketChoose: bool = false

var packetBankData: TowerDefensePacketBankData
var packetList: Array[TowerDefenseInGamePacketShow] = []
var currentCategory: String = ""
var currentIndex: int = -1
var _categoryGeneration: int = 0

var _guiTopShopButton: NinePatchButtonBase
var _guiTopAlmanacButton: NinePatchButtonBase
var _packetBankEntered: bool = false

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelPacketBankConfig.new()
    config.Init(data)
    packetBank = TOWER_DEFENSE_INGAME_PACKET_BANK.instantiate()
    packetBank.packetBankFeature = self
    control.AddUI(packetBank, 3)

func GameInit() -> void :
    var seedbankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank")
    packetBank.seedBank = seedbankFeature.seedBank
    _ConnectPacketBankSignals()
    PacketBankInit()

    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        CategoryChoose("Zombie")
    else:
        CategoryChoose("White", true)

func GameInitFromProgress() -> void :
    var seedbankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank")
    packetBank.seedBank = seedbankFeature.seedBank
    _ConnectPacketBankSignals()
    skipPacketChoose = true
    if seedbankFeature.config.method == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
        var _packetBankData: TowerDefensePacketBankData
        if CommandManager.debugPacketOpenAll:
            _packetBankData = TowerDefenseManager.GetPacketBankData("Total")
        else:
            _packetBankData = TowerDefenseManager.GetPacketBankData(config.packetBankType)
        SetPacketBankData(_packetBankData)

func GameStartFromProgress() -> void :
    var seedbankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank")
    if seedbankFeature:
        match seedbankFeature.config.method:
            TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.NOONE:
                skipPacketChoose = true
            TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
                if is_instance_valid(packetBankData):
                    var unlockPacket: Array[String] = packetBankData.GetUnlockPacket()
                    skipPacketChoose = unlockPacket.size() <= TowerDefenseManager.seedbankPacketMax
                else:
                    skipPacketChoose = false
            TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
                skipPacketChoose = true

func GameEntry() -> void :
    if !skipPacketChoose && currentCategory != "":
        CategoryChoose(currentCategory, true)

func PacketBankInit() -> void :
    var seedbankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank")
    var seedBank: TowerDefenseInGameSeedBank = seedbankFeature.seedBank
    packetBank.seedBank = seedBank
    var autoChooseReady: bool = false
    match seedbankFeature.config.method:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.NOONE:
            skipPacketChoose = true
            if Global.isMultiplayerMode:
                autoChooseReady = true

        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:

            var _packetBankData: TowerDefensePacketBankData
            if CommandManager.debugPacketOpenAll:
                _packetBankData = TowerDefenseManager.GetPacketBankData("Total")
            else:
                _packetBankData = TowerDefenseManager.GetPacketBankData(config.packetBankType)
            SetPacketBankData(_packetBankData)

            var unlockPacket: Array[String] = _packetBankData.GetUnlockPacket()
            skipPacketChoose = unlockPacket.size() <= TowerDefenseManager.seedbankPacketMax

            for levelPacketConfig: TowerDefenseLevelPacketConfig in seedbankFeature.config.packetList:
                if !is_instance_valid(levelPacketConfig.override):
                    PacketChooseFromName(levelPacketConfig.packetName, true)
                else:
                    var packetConfig: TowerDefensePacketConfig = levelPacketConfig.GetPacket()
                    var packet = seedBank.AddPacket(packetConfig)
                    packet.lock = true

            if !CommandManager.debugPacketSelect:
                if skipPacketChoose:
                    for packetName: String in unlockPacket:
                        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
                        seedBank.AddPacket(packetConfig)
                    seedBank.Ready()
                    if Global.isMultiplayerMode:
                        autoChooseReady = true

            if CommandManager.debugPacketSelect:
                skipPacketChoose = false

        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
            skipPacketChoose = true
            if control.isInit && !control.hasProgress:
                seedBank.DeleteAllPacket()
                for levelPacketConfig: TowerDefenseLevelPacketConfig in seedbankFeature.config.packetList:
                    var packetConfig: TowerDefensePacketConfig = levelPacketConfig.GetPacket()
                    seedBank.AddPacket(packetConfig)
                seedBank.Ready()
            if Global.isMultiplayerMode:
                autoChooseReady = true

            if CommandManager.debugPacketSelect:
                skipPacketChoose = false

    if autoChooseReady:
        _EmitChooseOver()

func SetPacketBankData(_data: TowerDefensePacketBankData) -> void :
    packetBankData = _data
    PacketClear()
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        CategoryChoose("Zombie")
    else:
        CategoryChoose("White", true)

func PacketChoose(packet: TowerDefenseInGamePacketShow) -> void :
    var nextIndex: int = packetList.find(packet)
    if packet.alive:
        if currentIndex != -1:
            if packetBank.seedBank && packetBank.seedBank.CanAddPacket():
                var cameraPos: Vector2 = packetBank.GetCameraPos()
                packetBank.CreateAnime(packet.config, cameraPos + packet.global_position)
                packet.alive = false

    if nextIndex != currentIndex:
        if currentIndex != -1:
            var prePacket: TowerDefenseInGamePacketShow = packetList[currentIndex]
            prePacket.Reset()

        currentIndex = nextIndex

func PacketListChoose(_packetList: Array) -> void :
    AudioManager.AudioPlay("PacketPick", AudioManagerEnum.TYPE.SFX)
    packetBank.ClearAnimeNode()
    for packetName: String in _packetList:
        var _config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfigReadOnly(packetName)
        if !_config.Unlock():
            continue
        if packetBank.seedBank.HasPacket(packetName):
            continue
        if packetBank.seedBank && packetBank.seedBank.CanAddPacket():
            var selectFlag: bool = false
            for packet: TowerDefenseInGamePacketShow in packetList:
                if packet.config.saveKey == packetName:
                    if packet.alive:
                        selectFlag = true
                        PacketChoose(packet)
                        break
            if !selectFlag:
                var cameraPos: Vector2 = packetBank.GetCameraPos()
                packetBank.CreateAnime(_config, cameraPos + Vector2(300.0, 260.0))

func PacketChooseFromName(packetName: String, lock: bool = false) -> void :
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
    if packetBank.seedBank.HasPacket(packetName):
        return
    if packetBank.seedBank.CanAddPacket():
        var packetInstance: TowerDefenseInGamePacketShow = packetBank.seedBank.AddPacket(packetConfig)
        packetInstance.lock = lock
    for packet: TowerDefenseInGamePacketShow in packetList:
        if packet.config.saveKey == packetName:
            if packet.alive:
                packet.alive = false

func PacketAlive(packetName: String) -> void :
    for packet: TowerDefenseInGamePacketShow in packetList:
        if packet.config.saveKey == packetName:
            packet.alive = true
            return

func RockButtonPressed() -> void :
    if !is_instance_valid(packetBank.seedBank) || packetBank.seedBank.packetNum <= 0:
        return
    _EmitChooseOver()

func _EmitChooseOver() -> void :
    chooseOver.emit()
    var reSelectPacketList: Array = []
    for packet: TowerDefenseInGamePacketShow in packetBank.seedBank.packetList:
        var saveKey: String = packet.originalSaveKey if packet.originalSaveKey != "" else packet.config.saveKey
        reSelectPacketList.append(saveKey)
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        GameSaveManager.SetKeyValue("ZombiePacketReSlect", reSelectPacketList)
    else:
        GameSaveManager.SetKeyValue("PacketReSlect", reSelectPacketList)
    GameSaveManager.Save()

    await control.get_tree().create_timer(1.0, false).timeout
    PacketClear()

func PacketClear() -> void :
    packetBank.ClearPackets()
    packetList = []
    currentIndex = 0

func CategoryChoose(_category: String, reFresh: bool = false) -> void :
    if currentCategory == _category && !reFresh:
        return
    if !is_instance_valid(packetBankData):
        return
    _categoryGeneration += 1
    var currentGeneration: int = _categoryGeneration
    currentCategory = _category
    PacketClear()

    if !packetBankData.category.has(_category):
        return
    var getConfigList: Array = packetBankData.category[_category]
    var configList: Array = []
    var unLoveList: Array = []
    for configName: String in getConfigList:
        var packetData: Dictionary = GameSaveManager.GetTowerDefensePacketValue(configName)
        if packetData.get_or_add("Love", false):
            configList.append(configName)
        else:
            unLoveList.append(configName)
    configList.append_array(unLoveList)

    var batchCount: int = 0
    for configName: String in configList:
        if _categoryGeneration != currentGeneration:
            return
        var _config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfigReadOnly(configName)
        if !_config.Unlock():
            continue
        var packet: TowerDefenseInGamePacketShow = packetBank.GetPacketFromPool()
        packetBank.AddPacketToContainer(packet)
        packet.Init(_config)
        packet.showLove = true
        packet.loveChange.connect(LoveChange)
        packet.pressed.connect(PacketChoose)
        packet.alive = !packetBank.seedBank.HasPacket(configName)
        if CommandManager.debugPacketOpenAll || \
Global.enterLevelMode == "OnlineLevel" || \
Global.enterLevelMode == "LoadLevel" || \
Global.enterLevelMode == "DiyLevel":
            packet.alive = !packetBank.seedBank.HasPacket(configName)
        packetList.append(packet)

        batchCount += 1
        if batchCount >= BATCH_SIZE:
            batchCount = 0
            await control.get_tree().process_frame
            if _categoryGeneration != currentGeneration:
                return

@warning_ignore("unused_parameter")
func LoveChange(packet: TowerDefenseInGamePacketShow) -> void :
    CategoryChoose(currentCategory, true)

func ReSelectButtonPressed() -> void :
    var reSelectPacketList: Array
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        reSelectPacketList = GameSaveManager.GetKeyValue("ZombiePacketReSlect")
    else:
        reSelectPacketList = GameSaveManager.GetKeyValue("PacketReSlect")
    packetBank.seedBank.DeleteAllPacket()
    PacketListChoose(reSelectPacketList)

func ViewButtonPressed() -> void :
    control.ViewMap()

func LoadPacketGroup(id: int) -> void :
    var packetGroupList: Array
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        packetGroupList = GameSaveManager.GetKeyValue("ZombiePacketGroup%d" % id)
    else:
        packetGroupList = GameSaveManager.GetKeyValue("PacketGroup%d" % id)
    packetBank.seedBank.DeleteAllPacket()
    PacketListChoose(packetGroupList)

func SavePacketGroup(id: int) -> void :
    var packetGroupList: Array = []
    for packet: TowerDefenseInGamePacketShow in packetBank.seedBank.packetList:
        var saveKey: String = packet.originalSaveKey if packet.originalSaveKey != "" else packet.config.saveKey
        packetGroupList.append(saveKey)
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        GameSaveManager.SetKeyValue("ZombiePacketGroup%d" % id, packetGroupList)
    else:
        GameSaveManager.SetKeyValue("PacketGroup%d" % id, packetGroupList)
    GameSaveManager.Save()

func ShopButtonPressed() -> void :
    DialogManager.DialogCreate("Shop")

func AlmanacButtonPressed() -> void :
    DialogManager.DialogCreate("Almanac")

func _ConnectPacketBankSignals() -> void :
    for card in packetBank.cardSort.get_node("VBoxContainer").get_children():
        card.choose.connect(CategoryChoose)
    packetBank.cardItem.choose.connect(CategoryChoose)
    packetBank.cardGraveStone.choose.connect(CategoryChoose)
    packetBank.cardZombie.choose.connect(CategoryChoose)
    packetBank.translate.get_node("RockButton").pressed.connect(RockButtonPressed)
    packetBank.translate.get_node("ReSelectButton").pressed.connect(ReSelectButtonPressed)
    packetBank.translate.get_node("ViewButton").pressed.connect(ViewButtonPressed)
    var packetGroup = packetBank.translate.get_node("PacketGroup")
    for i in range(1, 7):
        var buttonName = "PacketGroupButton" if i == 1 else "PacketGroupButton%d" % i
        var button = packetGroup.get_node(buttonName)
        button.loadGroup.connect(LoadPacketGroup)
        button.saveGroup.connect(SavePacketGroup)
    packetBank.get_node("ShopButton").pressed.connect(ShopButtonPressed)
    packetBank.get_node("AlmanacButton").pressed.connect(AlmanacButtonPressed)
    _InitGuiTopButtons()

func _InitGuiTopButtons() -> void :
    var guiTop = control.get_node_or_null("GUITop")
    if !is_instance_valid(guiTop):
        return
    _guiTopShopButton = guiTop.get_node_or_null("ShopButton")
    _guiTopAlmanacButton = guiTop.get_node_or_null("AlmanacButton")
    if is_instance_valid(_guiTopShopButton):
        _guiTopShopButton.visible = false
        _guiTopShopButton.pressed.connect(ShopButtonPressed)
    if is_instance_valid(_guiTopAlmanacButton):
        _guiTopAlmanacButton.visible = false
        _guiTopAlmanacButton.pressed.connect(AlmanacButtonPressed)
    packetBank.packetBankAnimationPlayer.animation_finished.connect(_OnPacketBankAnimationFinished)
    BattleEventBus.uiSwitched.connect(_OnUISwitched)

func _OnPacketBankAnimationFinished(animName: String) -> void :
    match animName:
        "Enter", "MobileEnter":
            _packetBankEntered = true
        "Exit", "MobileExit":
            _packetBankEntered = false
    _UpdateGuiTopButtonVisibility(GameSaveManager.GetConfigValue("MobilePreset"))
    _UpdatePacketBankButtonVisibility(GameSaveManager.GetConfigValue("MobilePreset"))

func _OnUISwitched(mobileMode: bool) -> void :
    if !is_instance_valid(packetBank) || !is_instance_valid(packetBank.translate):
        return
    _packetBankEntered = packetBank.translate.position.y < 500.0
    _UpdateGuiTopButtonVisibility(mobileMode)
    _UpdatePacketBankButtonVisibility(mobileMode)

func _UpdateGuiTopButtonVisibility(mobileMode: bool) -> void :
    if !is_instance_valid(_guiTopShopButton) || !is_instance_valid(_guiTopAlmanacButton):
        return
    if mobileMode || !_packetBankEntered:
        _guiTopShopButton.visible = false
        _guiTopAlmanacButton.visible = false
    else:
        _guiTopShopButton.visible = true
        _guiTopAlmanacButton.visible = true

func _UpdatePacketBankButtonVisibility(mobileMode: bool) -> void :
    if mobileMode:
        var shopButton = packetBank.get_node_or_null("ShopButton")
        var almanacButton = packetBank.get_node_or_null("AlmanacButton")
        if is_instance_valid(shopButton):
            shopButton.visible = false
        if is_instance_valid(almanacButton):
            almanacButton.visible = false
