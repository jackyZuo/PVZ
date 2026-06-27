class_name TowerDefenseBattleFeatureConveyorBelt extends TowerDefenseBattleFeature

const CONVEYOR_BELT_MANAGER = preload("uid://u3bg1snrdknl")

var conveyorBeltManager: ConveyorBeltManager
var config: TowerDefenseConveyorConfig

var packetPrioritySpawnList: Array[TowerDefenseLevelPacketConfig] = []
var packetList: Array[TowerDefenseConveyorPacketConfig] = []
var timer: float = 0.0
var running: bool = false



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseConveyorConfig.new()
    config.Init(data)
    conveyorBeltManager = CONVEYOR_BELT_MANAGER.instantiate()
    control.AddUIToTopBankContainer(conveyorBeltManager)
    packetPrioritySpawnList = config.packetPrioritySpawnList.duplicate(true)
    packetList = config.packetList.duplicate(true)
    conveyorBeltManager.Init(config.type)
    await control.get_tree().create_timer(0.1, false).timeout
    if is_instance_valid(TowerDefenseBattleFeatureWave.instance):
        TowerDefenseBattleFeatureWave.instance.bigWaveBegin.connect(WaveEventExecute)

func GameInit() -> void :
    if data.is_empty():
        conveyorBeltManager.visible = false

func GameInitFromProgress() -> void :
    if !data.is_empty() and is_instance_valid(conveyorBeltManager):
        conveyorBeltManager.visible = true

func GameStart() -> void :
    if is_instance_valid(conveyorBeltManager) and conveyorBeltManager.visible:
        running = true

func GameStartFromProgress() -> void :
    if is_instance_valid(conveyorBeltManager) and conveyorBeltManager.visible:
        running = true

func Process(_delta: float) -> void :
    conveyorBeltManager.UpdateSunDisplay()
    if !running:
        return
    conveyorBeltManager.UpdateBeltAnimation(_delta)
    timer += _delta
    var packetNum: int = conveyorBeltManager.GetPacketCount()
    var spawnTime: float = config.interval * (1.0 + float(floor(float(packetNum) / float(config.intervalIncreaseEvery))) * config.intervalMagnification)
    if timer > spawnTime && packetNum < 14:
        Spawn()
        timer = 0.0

func SyncSerialize() -> Dictionary:
    return {
        "timer": timer, 
        "running": running, 
    }

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("timer"):
        timer = _data["timer"]
    if _data.has("running"):
        running = _data["running"]

func SaveFeature() -> Dictionary:
    var packetDataList: Array = []
    if is_instance_valid(conveyorBeltManager):
        for child in conveyorBeltManager.GetPacketChildren():
            if child is TowerDefenseInGamePacketShow and is_instance_valid(child):
                packetDataList.append({
                    "saveKey": child.config.saveKey, 
                    "posX": child.position.x, 
                    "posY": child.position.y, 
                })
    return {
        "timer": timer, 
        "running": running, 
        "packetList": packetDataList, 
    }

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
    running = _data.get("running", false)
    if is_instance_valid(conveyorBeltManager):
        for child in conveyorBeltManager.GetPacketChildren():
            if is_instance_valid(child):
                var parent: Node = child.get_parent()
                if is_instance_valid(parent):
                    parent.remove_child(child)
                child.queue_free()
        for packetData: Dictionary in _data.get("packetList", []):
            var saveKey: String = packetData.get("saveKey", "")
            if saveKey == "":
                continue
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(saveKey)
            if !is_instance_valid(packetConfig):
                continue
            var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
            conveyorBeltManager.AddPacketToUI(packet)
            packet.Init(packetConfig)
            packet.coldDownOpen = false
            packet.onlyDraw = false
            packet.plantOnce = true
            packet.StartInit()
            packet.alive = true
            match config.type:
                "Default":
                    packet.showCost = false
                "Sun":
                    packet.useCost = true
                    packet.showCost = true
                    packet.start = true
            packet.Reset()
            packet.pressed.connect(TowerDefenseManager.GetPacketPickControl().PickPacket)
        conveyorBeltManager.ResetPacketPositions()



func Spawn() -> TowerDefenseInGamePacketShow:
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return null
    var packetConfigGet
    if packetPrioritySpawnList.size() <= 0:
        var weightPickItemList: Array[WeightPickItemBase] = []
        for packetConfig: TowerDefenseConveyorPacketConfig in packetList:
            var weight: float = packetConfig.weight
            var charcaterNum: int = TowerDefenseManager.GetCharacterNum(packetConfig.name, true)
            if packetConfig.maxNum != -1:
                if charcaterNum >= packetConfig.maxNum:
                    weight *= packetConfig.maxMagnification
            if packetConfig.minNum != -1:
                if charcaterNum < packetConfig.minNum:
                    weight *= packetConfig.minMagnification
            weightPickItemList.append(WeightPickItemBase.new(packetConfig, int(weight)))
        var pickPacketConfig: WeightPickItemBase = WeightPickMathine.Pick(weightPickItemList)
        if is_instance_valid(pickPacketConfig):
            packetConfigGet = pickPacketConfig.item.GetPacket()
    else:
        packetConfigGet = packetPrioritySpawnList.pop_front().GetPacket()
    var result = SpawnPacket(packetConfigGet)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost and is_instance_valid(packetConfigGet):
        MultiPlayerManager.SendConveyorSpawn(packetConfigGet.saveKey, config.type)
    return result

func SpawnPacket(packetConfig: TowerDefensePacketConfig) -> TowerDefenseInGamePacketShow:
    var packetNum: int = conveyorBeltManager.GetPacketCount()
    if packetNum > 14:
        return null
    if is_instance_valid(packetConfig):
        var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
        conveyorBeltManager.AddPacketToUI(packet)
        packet.Init(packetConfig)
        packet.coldDownOpen = false
        packet.onlyDraw = false
        packet.plantOnce = true
        packet.StartInit()
        packet.alive = true
        match config.type:
            "Default":
                packet.showCost = false
            "Sun":
                packet.useCost = true
                packet.showCost = true
                packet.start = true
        packet.Reset()
        packet.pressed.connect(TowerDefenseManager.GetPacketPickControl().PickPacket)
        return packet
    return null

func SpawnPacketFromSync(packetConfig: TowerDefensePacketConfig, packetType: String) -> TowerDefenseInGamePacketShow:
    var packetNum: int = conveyorBeltManager.GetPacketCount()
    if packetNum > 14:
        return null
    if is_instance_valid(packetConfig):
        var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
        conveyorBeltManager.AddPacketToUI(packet)
        packet.Init(packetConfig)
        packet.coldDownOpen = false
        packet.onlyDraw = false
        packet.plantOnce = true
        packet.StartInit()
        packet.alive = true
        match packetType:
            "Default":
                packet.showCost = false
            "Sun":
                packet.useCost = true
                packet.showCost = true
                packet.start = true
        packet.Reset()
        packet.pressed.connect(TowerDefenseManager.GetPacketPickControl().PickPacket)
        return packet
    return null

@warning_ignore("unused_parameter")
func WaveEventExecute(bigWaveId: int) -> void :
    if !conveyorBeltManager.visible || !running:
        return
    if config.waveEvent.size() <= bigWaveId:
        return
    for event: TowerDefenseConveyorEventBase in config.waveEvent[bigWaveId]:
        event.Execute()

func IsSunType() -> bool:
    return is_instance_valid(config) and config.type == "Sun"

func UpdateConveyorVisibility(mobile_preset: bool) -> Dictionary:
    var result: Dictionary = {
        "sun_visible": false, 
        "sun_bar_visible": false, 
        "mobile_sun_bar_visible": false, 
        "use_mobile_sun_label": false, 
    }
    var is_sun_type: bool = IsSunType()
    result.sun_visible = is_sun_type
    result.sun_bar_visible = is_sun_type
    result.mobile_sun_bar_visible = is_sun_type
    result.use_mobile_sun_label = is_sun_type and mobile_preset
    return result

func GetPacketChildren() -> Array[Node]:
    return conveyorBeltManager.GetPacketChildren()
