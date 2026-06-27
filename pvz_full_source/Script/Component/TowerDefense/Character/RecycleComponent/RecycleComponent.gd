class_name RecycleComponent extends ComponentBase

var parent: TowerDefenseCharacter

var _sync_sun_velocity: Vector2 = Vector2.ZERO
var _sync_deserializing: bool = false

func GetName() -> String:
    return "RecycleComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func Recycle(percentage: float = 0.2, _destroy: bool = true) -> void :
    if parent.cost <= 0.0:
        parent.Destroy()
        return
    var sunVelocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0)
    if _sync_deserializing and _sync_sun_velocity != Vector2.ZERO:
        sunVelocity = _sync_sun_velocity
        _sync_sun_velocity = Vector2.ZERO
        _sync_deserializing = false
    else:
        _sync_sun_velocity = sunVelocity
    if parent.instance.hypnoses:
        parent.BrainSunCreate(parent.global_position, int(parent.cost * percentage), TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, sunVelocity, 980.0)
    else:
        parent.SunCreate(parent.global_position, int(parent.cost * percentage), TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, sunVelocity, 980.0)
    if _destroy:
        parent.isShovel = true
        parent.Destroy()

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {}
    if _sync_sun_velocity != Vector2.ZERO:
        data["sun_velocity_x"] = _sync_sun_velocity.x
        data["sun_velocity_y"] = _sync_sun_velocity.y
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("sun_velocity_x"):
        _sync_sun_velocity = Vector2(_data.get("sun_velocity_x", 0.0), _data.get("sun_velocity_y", 0.0))
        _sync_deserializing = true
