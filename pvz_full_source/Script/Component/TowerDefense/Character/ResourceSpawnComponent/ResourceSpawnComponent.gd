
class_name ResourceSpawnComponent extends ComponentBase


const HEALTH = preload("uid://b8c40r4tk45sf")

const MAX_EFFECT_COUNT: = 100


var parent: TowerDefenseCharacter

var _sync_last_sun_velocity: Vector2 = Vector2.ZERO
var _sync_last_coin_velocity: Vector2 = Vector2.ZERO
var _sync_deserializing: bool = false


func GetName() -> String:
    return "ResourceSpawnComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready








func SpawnPacket(packetConfig: TowerDefensePacketConfig, pos: Vector2, aliveTime: float, isFall: bool, useCost: bool = false) -> TowerDefenseInGamePacketShow:
    return TowerDefenseManager.SpawnPacket(packetConfig, pos, aliveTime, isFall, useCost)


func YBCreate(pos: Vector2, num: int, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _collect: bool = false) -> void :
    TowerDefenseManager.YBCreate(pos, num, parent.GetGroundHeight(pos.y) - parent.groundHeight * 2, _velocity, _gravity, _collect)


func CoinCreate(pos: Vector2, num: int, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _collect: bool = false) -> void :
    if _sync_deserializing and _sync_last_coin_velocity != Vector2.ZERO:
        _velocity = _sync_last_coin_velocity
        _sync_last_coin_velocity = Vector2.ZERO
        _sync_deserializing = false
    else:
        _sync_last_coin_velocity = _velocity
    TowerDefenseManager.CoinCreate(pos, num, parent.GetGroundHeight(pos.y) - parent.groundHeight * 2, _velocity, _gravity, _collect)


func LuckyBagCreate(pos: Vector2, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0) -> void :
    TowerDefenseManager.LuckyBagCreate(pos, parent.GetGroundHeight(pos.y) - parent.groundHeight * 2, _velocity, _gravity)


func SunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _moveStopTime: float = -1) -> TowerDefenseSunBase:
    if _sync_deserializing and _sync_last_sun_velocity != Vector2.ZERO:
        _velocity = _sync_last_sun_velocity
        _sync_last_sun_velocity = Vector2.ZERO
        _sync_deserializing = false
    else:
        _sync_last_sun_velocity = _velocity
    return TowerDefenseManager.SunCreate(pos, sunNum, movingMethod, parent.GetGroundHeight(pos.y) - parent.groundHeight * 2, _velocity, _gravity, _moveStopTime)


func BrainSunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _moveStopTime: float = -1) -> TowerDefenseSunBase:
    return TowerDefenseManager.BrainSunCreate(pos, sunNum, movingMethod, parent.GetGroundHeight(pos.y) - parent.groundHeight * 2, _velocity, _gravity, _moveStopTime)


func JalapenoSunCreate(pos: Vector2, sunNum: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _velocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0), _gravity: float = 980.0, _moveStopTime: float = -1) -> TowerDefenseSunBase:
    var jalapenoSun: TowerDefenseSunJalapeno = TowerDefenseManager.JalapenoSunCreate(pos, sunNum, movingMethod, parent.GetGroundHeight(pos.y) - parent.groundHeight * 2, _velocity, _gravity, _moveStopTime)
    jalapenoSun.gridPos = parent.gridPos
    return jalapenoSun


func ExplodeSunCreate(pos: Vector2, sunNum: int, sunOnce: int, movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, _speed: float = 0.0, _gravity: float = 0.0, _moveStopTime: float = -1) -> void :
    while sunNum > 0:
        SunCreate(pos, sunOnce, movingMethod, Vector2.from_angle(PI / 2.0 + randf_range( - PI / 12.0, PI / 12.0)) * _speed * randf_range(0.5, 1.5), _gravity, _moveStopTime)
        sunNum -= sunOnce



func HealthEffect(num: float) -> void :
    parent.instance.Health(num)
    if TowerDefenseManager.GetEffectCount() > MAX_EFFECT_COUNT:
        return
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(HEALTH, parent.gridPos, "Idle")
    TowerDefenseCharacter.characterNode.add_child(effect)
    effect.gridPos = parent.gridPos
    effect.global_position = Vector2(parent.shadowSprite.global_position.x, parent.shadowComponent.GetShadowPosition().y)

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {}
    if _sync_last_sun_velocity != Vector2.ZERO:
        data["sun_velocity_x"] = _sync_last_sun_velocity.x
        data["sun_velocity_y"] = _sync_last_sun_velocity.y
    if _sync_last_coin_velocity != Vector2.ZERO:
        data["coin_velocity_x"] = _sync_last_coin_velocity.x
        data["coin_velocity_y"] = _sync_last_coin_velocity.y
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("sun_velocity_x"):
        _sync_last_sun_velocity = Vector2(_data.get("sun_velocity_x", 0.0), _data.get("sun_velocity_y", 0.0))
        _sync_deserializing = true
    if _data.has("coin_velocity_x"):
        _sync_last_coin_velocity = Vector2(_data.get("coin_velocity_x", 0.0), _data.get("coin_velocity_y", 0.0))
        _sync_deserializing = true
