
class_name RiseComponent extends ComponentBase


var parent: TowerDefenseCharacter

var _sync_duration: float = -1.0
var _sync_deserializing: bool = false


func GetName() -> String:
    return "RiseComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready







func Rise(duration: float = randf_range(0.4, 0.6), delay: float = 0.0, createDirt: bool = true, changeState: bool = true, from: float = 150.0) -> void :
    if _sync_deserializing and _sync_duration >= 0.0:
        duration = _sync_duration
        _sync_duration = -1.0
        _sync_deserializing = false
    else:
        _sync_duration = duration
    parent.isRise = true
    var rememberShadowVisible: bool = parent.shadowSprite.visible && !parent.invisible
    var saveGrounHeight: float = parent.groundHeight
    parent.shadowSprite.visible = false
    var viewport: Viewport = parent.get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    parent.SetSpriteGroupShaderParameter("discardDownPos", (vt * (parent.spriteGroup.global_position + Vector2(0, 36 - saveGrounHeight))).y)
    parent.groundHeight = - from
    parent.z = parent.groundHeight
    parent.spriteGroup.position.y = - parent.z
    if changeState:
        parent.OnRiseStart()
        await parent.get_tree().physics_frame
        await parent.get_tree().physics_frame
        await parent.get_tree().create_timer(delay, false).timeout
    var riseTween = parent.create_tween()
    riseTween.set_ease(Tween.EASE_OUT)
    riseTween.set_trans(Tween.TRANS_CUBIC)
    if parent is TowerDefenseZombie && parent.inWater:
        riseTween.tween_property(parent, ^"groundHeight", - parent.get("waterHeight"), duration).from( - from)
    else:
        riseTween.tween_property(parent, ^"groundHeight", saveGrounHeight, duration).from( - from)
    await parent.get_tree().create_timer(0.1, false).timeout
    if createDirt:
        if !parent.inWater:
            parent.CreateDirt()
        else:
            parent.CreateSplash()
    await riseTween.finished
    if !parent.inWater:
        parent.groundHeight = saveGrounHeight
        parent.z = saveGrounHeight
        parent.SetSpriteGroupShaderParameter("discardDownPos", 10000.0)
    parent.isRise = false
    if changeState:
        parent.OnRiseEnd()
    if !parent.inWater:
        parent.shadowSprite.visible = rememberShadowVisible
    parent.riseOver.emit()

func ExportComponentSave() -> Dictionary:
    return {
        "isRise": parent.isRise if is_instance_valid(parent) else false, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    if is_instance_valid(parent):
        parent.isRise = _data.get("isRise", false)

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "isRise": parent.isRise if is_instance_valid(parent) else false, 
    }
    if _sync_duration >= 0.0:
        data["duration"] = _sync_duration
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    if is_instance_valid(parent):
        parent.isRise = _data.get("isRise", parent.isRise)
    if _data.has("duration"):
        _sync_duration = _data.get("duration", -1.0)
        _sync_deserializing = true
