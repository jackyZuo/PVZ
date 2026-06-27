class_name TowerDefenseBattleFeatureSeedBank extends TowerDefenseBattleFeature

const TOWER_DEFENSE_INGAME_SEED_BANK = preload("uid://2vh1csqbvbqx")

var seedBank: TowerDefenseInGameSeedBank
var config: TowerDefenseLevelSeedBankConfig



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelSeedBankConfig.new()
    config.Init(data)
    seedBank = TOWER_DEFENSE_INGAME_SEED_BANK.instantiate()
    control.AddUIToTopBankContainer(seedBank)

func Ready() -> void :
    var method: int = TowerDefenseManager.currentLevelConfig.packetBankMethod
    if method == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
        if is_instance_valid(seedBank):
            seedBank.visible = false

func GameStart() -> void :
    seedBank.Start()

func GameStartFromProgress() -> void :
    seedBank.StartFromProgress()

func Process(_delta: float) -> void :
    if is_instance_valid(seedBank) and seedBank.visible:
        seedBank.UpdateDisplay()

func SyncSerialize() -> Dictionary:
    return {}

func SyncDeserialize(_data: Dictionary) -> void :
    pass

func SaveFeature() -> Dictionary:
    print("[Save] 保存Feature[SeedBank]...")
    var packetDataList: Array = []
    if is_instance_valid(seedBank):
        for packet: TowerDefenseInGamePacketShow in seedBank.packetList:
            if is_instance_valid(packet):
                var changeCostListSave: Array = []
                if is_instance_valid(packet.config):
                    for changeCost: TowerDefensePacketChangeCost in packet.config.changeCostList:
                        changeCostListSave.append(changeCost.ExportSave())
                packetDataList.append({
                    "saveKey": packet.config.saveKey, 
                    "showLove": packet.showLove, 
                    "showCost": packet.showCost, 
                    "onlyDraw": packet.onlyDraw, 
                    "alive": packet.alive, 
                    "lock": packet.lock, 
                    "plantOnce": packet.plantOnce, 
                    "useCost": packet.useCost, 
                    "openShadow": packet.openShadow, 
                    "start": packet.start, 
                    "select": packet.select, 
                    "coldDown": packet.coldDown, 
                    "coldDownOpen": packet.coldDownOpen, 
                    "coldDownTimer": packet.coldDownTimer, 
                    "aliveTime": packet.aliveTime, 
                    "aliveTimer": packet.aliveTimer, 
                    "blinkTimer": packet.blinkTimer, 
                    "blink": packet.blink, 
                    "height": packet.height, 
                    "savePosX": packet.savePos.x, 
                    "savePosY": packet.savePos.y, 
                    "overrideSave": packet.config.override.Export() if is_instance_valid(packet.config) and is_instance_valid(packet.config.override) else {}, 
                    "canChangeCost": packet.config.canChangeCost if is_instance_valid(packet.config) else true, 
                    "changeCostList": changeCostListSave, 
                })
    var result: Dictionary = {
        "sunNum": TowerDefenseManager.GetSun(), 
        "packetNum": seedBank.packetNum if is_instance_valid(seedBank) else 0, 
        "packetList": packetDataList, 
    }
    print("[Save] Feature[SeedBank]保存完成: sunNum=%d, packetNum=%d, packetList=%d" % [result.sunNum, result.packetNum, packetDataList.size()])
    return result

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    print("[Load] 加载Feature[SeedBank]... (数据项: %d)" % _data.size())
    if !is_instance_valid(seedBank):
        print("[Load] Feature[SeedBank]加载失败: seedBank无效")
        return
    TowerDefenseManager.SetSun(_data.get("sunNum", 50))
    seedBank.DeleteAllPacket()
    seedBank.packetNum = _data.get("packetNum", 0)
    for packetData: Dictionary in _data.get("packetList", []):
        var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShowWithConfig()
        seedBank.packetContainer.add_child(packet)
        var saveKey: String = packetData.get("saveKey", "")
        if saveKey != "":
            packet.config = TowerDefenseManager.GetPacketConfig(saveKey)
            var overrideData: Dictionary = packetData.get("overrideSave", {})
            if overrideData.size() > 0 and is_instance_valid(packet.config):
                var override: TowerDefensePacketOverride = TowerDefensePacketOverride.new()
                override.Init(overrideData)
                packet.config.override = override
            packet.Init(packet.config)
        packet.showLove = packetData.get("showLove", false)
        packet.showCost = packetData.get("showCost", true)
        packet.onlyDraw = packetData.get("onlyDraw", false)
        packet.alive = packetData.get("alive", true)
        packet.lock = packetData.get("lock", false)
        packet.plantOnce = packetData.get("plantOnce", false)
        packet.useCost = packetData.get("useCost", true)
        packet.openShadow = packetData.get("openShadow", false)
        packet.start = packetData.get("start", false)
        packet.select = packetData.get("select", false)
        packet.coldDown = packetData.get("coldDown", 0.0)
        packet.coldDownOpen = packetData.get("coldDownOpen", false)
        packet.coldDownTimer = packetData.get("coldDownTimer", 0.0)
        packet.aliveTime = packetData.get("aliveTime", -1)
        packet.aliveTimer = packetData.get("aliveTimer", 0.0)
        packet.blinkTimer = packetData.get("blinkTimer", 0.0)
        packet.blink = packetData.get("blink", false)
        packet.height = packetData.get("height", -1)
        packet.savePos = Vector2(packetData.get("savePosX", 0.0), packetData.get("savePosY", 0.0))
        if is_instance_valid(packet.config):
            packet.config.canChangeCost = packetData.get("canChangeCost", true)
            packet.config.changeCostList.clear()
            for changeCostData: Dictionary in packetData.get("changeCostList", []):
                packet.config.changeCostList.append(TowerDefensePacketChangeCost.ImportSave(changeCostData))
        seedBank.packetList.append(packet)
        seedBank.packetNameSet[saveKey] = true
    print("[Load] Feature[SeedBank]加载完成: sunNum=%d, packetNum=%d, packetList=%d" % [_data.get("sunNum", 50), _data.get("packetNum", 0), _data.get("packetList", []).size()])
