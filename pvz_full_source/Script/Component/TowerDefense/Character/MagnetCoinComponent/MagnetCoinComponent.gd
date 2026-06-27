class_name MagnetCoinComponent extends ComponentBase

signal coinGet(num: int)

@export var posMarker: Marker2D
@export var magnetTime: float = 5.0
@export var magnetNum: int = -1
@export var useRegistryCoinTypes: bool = true
@export_enum("Silver", "Gold", "Diamond", "LuckyBag", "YQ", "YB1", "YB2", "GoldShard") var objectList: Array[int] = [0, 1, 2, 4, 5, 6]

var parent: TowerDefenseCharacter

var coinList: Array[TowerDefenseCoinBase]

var timer: float = 0

var _registryCoinObjectIds: Array[int] = []

func GetName() -> String:
    return "MagnetCoinComponent"

func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    if useRegistryCoinTypes:
        _RefreshRegistryCoinTypes()

func _RefreshRegistryCoinTypes() -> void :
    _registryCoinObjectIds.clear()
    var coin_configs: Array[DropItemConfig] = DropItemRegistry.GetByCategory(TowerDefenseEnum.DROP_ITEM_CATEGORY.COIN)
    for config: DropItemConfig in coin_configs:
        if config.coinObjectId >= 0:
            _registryCoinObjectIds.append(config.coinObjectId)

func _GetCoinObjectIds() -> Array[int]:
    if useRegistryCoinTypes && _registryCoinObjectIds.size() > 0:
        return _registryCoinObjectIds
    return objectList

func _exit_tree() -> void :
    for coin: TowerDefenseCoinBase in coinList:
        coin.isCollect = false
        coin.add_to_group("Coin")
        if GameSaveManager.GetFeatureValue("CoinCollect") && get_tree().get_node_count_in_group("GoldMagnet") <= 0:
            coin.Collection()
        else:
            coin.over = false
            coin.spriteNode.position = Vector2.ZERO
            coin.height = 0.0
            coin.moveComponent.SetVelocity(Vector2(randf_range(-50, 50), -200))
            coin.moveComponent.SetGravity(980.0)

func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return
    if timer < magnetTime:
        timer += delta
    else:
        timer -= randf() * magnetTime
    if coinList.size() > 0:
        for coin: TowerDefenseCoinBase in coinList:
            if !is_instance_valid(coin):
                coinList.erase(coin)
                break
            coin.global_position = lerp(coin.global_position, posMarker.global_position, delta * 5.0)
            if coin.global_position.distance_to(posMarker.global_position) <= 10:
                AudioManager.AudioPlay(coin.pickAudio, AudioManagerEnum.TYPE.SFX)
                coinGet.emit(coin.num)
                coin.Destroy()
                coinList.erase(coin)

func CanCoinDraw() -> bool:
    if timer < magnetTime:
        return false
    var ids: Array[int] = _GetCoinObjectIds()
    var num: int = get_tree().get_node_count_in_group("Coin")
    for coin in get_tree().get_nodes_in_group("Coin"):
        if !ids.has(coin.coinObjectId):
            num -= 1
    return num > 0

func CoinDraw() -> void :
    timer = 0.0
    var ids: Array[int] = _GetCoinObjectIds()
    var num: int = magnetNum
    for coin: TowerDefenseCoinBase in get_tree().get_nodes_in_group("Coin"):
        if !ids.has(coin.coinObjectId):
            continue
        if coin.isCollect:
            continue
        if !coin.canMagnet:
            continue
        if num != -1:
            if num > 0:
                num -= 1
            else:
                continue
        coin.isCollect = true
        coin.remove_from_group("Coin")
        coinList.append(coin)
