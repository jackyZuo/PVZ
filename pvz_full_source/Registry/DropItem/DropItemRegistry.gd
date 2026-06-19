class_name DropItemRegistry

static var isInit: bool = false
static var dropItemDictionary: Dictionary[StringName, DropItemConfig] = {}
static var dropItemByIdDictionary: Dictionary[int, DropItemConfig] = {}
static var dropItemByCoinObjectIdDictionary: Dictionary[int, DropItemConfig] = {}

static var _sunHandler: SunDropItemHandler
static var _coinHandler: CoinDropItemHandler
static var _luckyBagHandler: LuckyBagDropItemHandler
static var _jalapenoSunHandler: JalapenoSunDropItemHandler
static var _brainSunHandler: BrainSunDropItemHandler

static func Init() -> void :
    if isInit:
        return
    isInit = true
    _CreateHandlers()
    RegisterInit()

static func _CreateHandlers() -> void :
    _sunHandler = SunDropItemHandler.new()
    _coinHandler = CoinDropItemHandler.new()
    _luckyBagHandler = LuckyBagDropItemHandler.new()
    _jalapenoSunHandler = JalapenoSunDropItemHandler.new()
    _brainSunHandler = BrainSunDropItemHandler.new()

static func RegisterInit() -> void :
    Register(_CreateConfig("Sun", ObjectManagerConfig.OBJECT.SUN, preload("uid://dk3bkihnh1i0l"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.SUN, 25, "", "Sun", -1, _sunHandler))
    Register(_CreateConfig("SunBrain", ObjectManagerConfig.OBJECT.SUN_BRAIN, preload("uid://d161xee5m0kkw"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.SUN, 25, "", "Sun", -1, _brainSunHandler))
    Register(_CreateConfig("SunJalapeno", ObjectManagerConfig.OBJECT.SUN_JALAPENO, preload("uid://da7lvlco511ds"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.SUN, 25, "", "Sun", -1, _jalapenoSunHandler))

    Register(_CreateConfig("CoinSilver", ObjectManagerConfig.OBJECT.COIN_SILVER, preload("uid://csynbfevdbiju"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.COIN, 10, "CoinFall", "CoinPick", 0, _coinHandler))
    Register(_CreateConfig("CoinGold", ObjectManagerConfig.OBJECT.COIN_GOLD, preload("uid://kbif4idtgolo"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.COIN, 50, "CoinFall", "CoinPick", 1, _coinHandler))
    Register(_CreateConfig("CoinDiamond", ObjectManagerConfig.OBJECT.COIN_DIAMOND, preload("uid://6b78y08u52f5"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.COIN, 1000, "CoinFall", "CoinPick", 2, _coinHandler))
    Register(_CreateConfig("CoinTQ", ObjectManagerConfig.OBJECT.COIN_TQ, preload("uid://733w81lrellb"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.COIN, 10, "CoinFall", "CoinPick", 4, _coinHandler))
    Register(_CreateConfig("CoinYB1", ObjectManagerConfig.OBJECT.COIN_YB1, preload("uid://c25ngfvpp0uo3"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.COIN, 50, "CoinFall", "CoinPick", 5, _coinHandler))
    Register(_CreateConfig("CoinYB2", ObjectManagerConfig.OBJECT.COIN_YB2, preload("uid://1twddwaolt4r"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.COIN, 1000, "CoinFall", "CoinPick", 6, _coinHandler))

    Register(_CreateConfig("LuckyBag", ObjectManagerConfig.OBJECT.COIN_LUCKY_BAG, preload("uid://bnrh1k2cgopsn"), 100, TowerDefenseEnum.DROP_ITEM_CATEGORY.SPECIAL, 0, "CoinFall", "CoinPick", 3, _luckyBagHandler))

static func _CreateConfig(_name: StringName, _id: ObjectManagerConfig.OBJECT, _scene: PackedScene, _poolMaxNum: int, _category: TowerDefenseEnum.DROP_ITEM_CATEGORY, _value: int, _fallAudio: String = "CoinFall", _pickAudio: String = "CoinPick", _coinObjectId: int = -1, _handler: DropItemHandler = null) -> DropItemConfig:
    var config: = DropItemConfig.new()
    config.name = _name
    config.id = _id
    config.scene = _scene
    config.poolMaxNum = _poolMaxNum
    config.category = _category
    config.value = _value
    config.fallAudio = _fallAudio
    config.pickAudio = _pickAudio
    config.coinObjectId = _coinObjectId
    config.handler = _handler
    return config

static func Register(config: DropItemConfig) -> void :
    dropItemDictionary[config.name] = config
    dropItemByIdDictionary[config.id] = config
    if config.coinObjectId >= 0:
        dropItemByCoinObjectIdDictionary[config.coinObjectId] = config

static func Get(_name: StringName) -> DropItemConfig:
    Init()
    if dropItemDictionary.has(_name):
        return dropItemDictionary[_name]
    return null

static func GetById(id: ObjectManagerConfig.OBJECT) -> DropItemConfig:
    Init()
    if dropItemByIdDictionary.has(id):
        return dropItemByIdDictionary[id]
    return null

static func GetByCoinObjectId(coinObjectId: int) -> DropItemConfig:
    Init()
    if dropItemByCoinObjectIdDictionary.has(coinObjectId):
        return dropItemByCoinObjectIdDictionary[coinObjectId]
    return null

static func GetByCategory(category: TowerDefenseEnum.DROP_ITEM_CATEGORY) -> Array[DropItemConfig]:
    Init()
    var result: Array[DropItemConfig] = []
    for config: DropItemConfig in dropItemDictionary.values():
        if config.category == category:
            result.append(config)
    return result

static func GetPoolKeyByCoinObjectId(coinObjectId: int) -> ObjectManagerConfig.OBJECT:
    var config: DropItemConfig = GetByCoinObjectId(coinObjectId)
    if config:
        return config.id
    return ObjectManagerConfig.OBJECT.NOONE

static func GetHandler(_name: StringName) -> DropItemHandler:
    var config: DropItemConfig = Get(_name)
    if config && config.handler:
        return config.handler
    return null

static func GetHandlerById(id: ObjectManagerConfig.OBJECT) -> DropItemHandler:
    var config: DropItemConfig = GetById(id)
    if config && config.handler:
        return config.handler
    return null

static func GetLuckyBagHandler() -> LuckyBagDropItemHandler:
    Init()
    return _luckyBagHandler

static func GetJalapenoSunHandler() -> JalapenoSunDropItemHandler:
    Init()
    return _jalapenoSunHandler

static func Reset() -> void :
    Init()
    for config: DropItemConfig in dropItemDictionary.values():
        if config.handler:
            config.handler.Reset()

static func GetNames() -> Array[StringName]:
    Init()
    var names: Array[StringName] = []
    names.append_array(dropItemDictionary.keys())
    return names

static func GetIds() -> Array[int]:
    Init()
    var ids: Array[int] = []
    ids.append_array(dropItemByIdDictionary.keys())
    return ids
