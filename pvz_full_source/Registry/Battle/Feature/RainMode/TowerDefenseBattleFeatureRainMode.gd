class_name TowerDefenseBattleFeatureRainMode extends TowerDefenseBattleFeature

const RAIN_MANAGER = preload("res://Registry/Battle/Feature/RainMode/RainManager/RainManager.tscn")

var rainManager: RainManager
var config: TowerDefenseRainModeConfig
var packetList: Array = []
var running: bool = false
var timer: float = 0.0



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseRainModeConfig.new()
    config.Init(data)
    rainManager = RAIN_MANAGER.instantiate()
    control.AddUIToTopBankContainer(rainManager)
    rainManager.Init(config.type)

func GameInit() -> void :
    packetList = config.packetList.duplicate(true)
    if data.is_empty():
        rainManager.visible = false

func GameInitFromProgress() -> void :
    packetList = config.packetList.duplicate(true)

func GameReady() -> void :
    running = false

func GameStart() -> void :
    if is_instance_valid(rainManager) and rainManager.visible:
        running = true

func GameStartFromProgress() -> void :
    if is_instance_valid(rainManager) and rainManager.visible:
        running = true

func Process(delta: float) -> void :
    if is_instance_valid(rainManager):
        rainManager.UpdateSunDisplay()
    if !running:
        return
    if packetList.size() <= 0:
        return
    timer += delta
    var spawnTime: float = config.interval
    if timer > spawnTime:
        Spawn()
        timer = 0.0



func Spawn() -> TowerDefenseInGamePacketShow:
    if packetList.size() <= 0:
        return null
    var weightPickItemList: Array[WeightPickItemBase] = []
    for packetConfig: TowerDefenseRainModePacketConfig in packetList:
        var weight: float = packetConfig.weight
        var charcaterNum: int = TowerDefenseManager.GetCharacterNum(packetConfig.name)
        if packetConfig.maxNum != -1:
            if charcaterNum >= packetConfig.maxNum:
                weight *= packetConfig.maxMagnification
        if packetConfig.minNum != -1:
            if charcaterNum < packetConfig.minNum:
                weight *= packetConfig.minMagnification
        weightPickItemList.append(WeightPickItemBase.new(packetConfig, int(weight)))
    var pickPacketConfig: WeightPickItemBase = WeightPickMathine.Pick(weightPickItemList)
    var packetConfigGet = pickPacketConfig.item.GetPacket()
    return SpawnPacket(packetConfigGet)

func SpawnPacket(packetConfig: TowerDefensePacketConfig) -> TowerDefenseInGamePacketShow:
    var posX: float = randf_range(TowerDefenseManager.GetMapGridBeginPos().x, TowerDefenseManager.GetMapGroundRight())
    return TowerDefenseManager.SpawnPacket(packetConfig, Vector2(posX, TowerDefenseManager.GetMapGridBeginPos().y - 100), config.aliveTime, true, config.type == "Sun")

func IsSunType() -> bool:
    return is_instance_valid(config) and config.type == "Sun"

func UpdateRainVisibility(mobile_preset: bool) -> Dictionary:
    var is_sun_type: bool = IsSunType()
    return {
        "sun_visible": is_sun_type, 
        "sun_bar_visible": is_sun_type, 
        "mobile_sun_bar_visible": is_sun_type, 
        "use_mobile_sun_label": is_sun_type and mobile_preset, 
    }

func SaveFeature() -> Dictionary:
    return {
        "timer": timer, 
        "running": running, 
        "rain_visible": rainManager.visible if is_instance_valid(rainManager) else false, 
    }

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
    running = _data.get("running", false)
    if is_instance_valid(rainManager):
        rainManager.visible = _data.get("rain_visible", false)
