
class_name ShadowComponent extends ComponentBase


const SHADOW_SCALE_FACTOR: = 900.0


@export var followHeight: bool = false


var parent: TowerDefenseCharacter

var saveShadowScale: Vector2

var saveShadowPosition: Vector2

var saveTransformPointScale: Vector2 = Vector2.ONE

var _initialized: bool = false
var _pendingVisible: bool = true
var shadowDisabled: bool = false

var _dirty: bool = true

var _last_z: float = 0.0

var _last_transform_scale: Vector2 = Vector2.ONE

var _last_ground_height: float = 0.0


func GetName() -> String:
    return "ShadowComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready
    _initialized = true
    parent.shadowSprite.visible = _pendingVisible && !parent.invisible && !shadowDisabled
    MarkDirty()


func Init() -> void :
    saveShadowScale = parent.shadowSprite.scale
    saveShadowPosition = parent.shadowSprite.global_position
    saveTransformPointScale = parent.transformPoint.scale
    MarkDirty()


func MarkDirty() -> void :
    _dirty = true


func UpdateShadow() -> void :
    var tps: Vector2 = parent.transformPoint.scale
    var scaleRatio: Vector2 = Vector2(abs(tps.x) / max(abs(saveTransformPointScale.x), 0.001), abs(tps.y) / max(abs(saveTransformPointScale.y), 0.001))
    parent.shadowSprite.scale = saveShadowScale * (1.0 - parent.z / SHADOW_SCALE_FACTOR) * scaleRatio
    if followHeight:
        parent.shadowSprite.global_position.y = parent.transformPoint.global_position.y
    parent.shadowSprite.global_position.y = saveShadowPosition.y - parent.groundHeight * abs(parent.transformPoint.global_scale.y)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !_initialized:
        return
    if parent.invisible || shadowDisabled:
        parent.shadowSprite.visible = false
        return
    if !parent.shadowSprite.is_visible_in_tree():
        return

    var current_z: float = parent.z
    var current_scale: Vector2 = parent.transformPoint.scale
    var current_ground_height: float = parent.groundHeight
    if !_dirty && (current_z != _last_z || current_scale != _last_transform_scale || current_ground_height != _last_ground_height):
        _dirty = true
    if _dirty:
        _last_z = current_z
        _last_transform_scale = current_scale
        _last_ground_height = current_ground_height
        _dirty = false
        UpdateShadow()



func SetVisible(_visible: bool) -> void :
    _pendingVisible = _visible
    if !_initialized:
        return
    parent.shadowSprite.visible = _visible && !parent.invisible && !shadowDisabled



func GetShadowPosition() -> Vector2:
    return saveShadowPosition



func GetShadowScale() -> Vector2:
    return saveShadowScale
