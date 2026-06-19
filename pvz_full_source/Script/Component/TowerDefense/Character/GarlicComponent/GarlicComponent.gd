class_name GarlicComponent extends ComponentBase

const ZOMBIE_HEAD_GROSSOUT = preload("uid://bbidqxovk4j7y")

var parent: TowerDefenseZombie

var changeLineTween: Tween = null
var _changeLineCancelled: bool = false

var _sync_move_dir: int = 0
var _sync_deserializing: bool = false

func GetName() -> String:
    return "GarlicComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func Garlic() -> void :
    if parent.nearDie || parent.die:
        parent.Die()
        return
    if parent.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.GARLIC:
        return
    if parent.isGarlic:
        return
    parent.isGarlic = true
    parent.state.send_event("ToGarlic")
    await parent.get_tree().create_timer(0.5, false).timeout
    AudioManager.AudioPlay("Yuck", AudioManagerEnum.TYPE.SFX)
    var replaceUse: Array[bool] = []
    replaceUse.resize(parent.garlicFliters.size())
    replaceUse.fill(true)
    var saveReplace: Texture2D = parent.sprite.GetReplace(parent.garlicReplace)
    parent.sprite.SetReplace(parent.garlicReplace, ZOMBIE_HEAD_GROSSOUT)
    for id in parent.garlicFliters.size():
        replaceUse[id] = parent.sprite.GetFliter(parent.garlicFliters[id])
    parent.sprite.SetFliters(parent.garlicFliters, false)
    await parent.get_tree().create_timer(0.5, false).timeout
    parent.sprite.SetReplace(parent.garlicReplace, saveReplace)
    if !parent.nearDie && !parent.die:
        parent.Walk()
        for id in parent.garlicFliters.size():
            if replaceUse[id]:
                parent.sprite.SetFliter(parent.garlicFliters[id], true)
        await ChangeLine()
    parent.isGarlic = false

func ChangeLine() -> void :
    if parent.isChangeLine:
        return
    parent.isChangeLine = true
    _changeLineCancelled = false
    var mapGridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var mapGridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var moveDir = 0
    if parent.gridPos.y == 1:
        moveDir = 1
    elif parent.gridPos.y == mapGridNum.y:
        moveDir = -1
    elif _sync_deserializing and _sync_move_dir != 0:
        moveDir = _sync_move_dir
        _sync_deserializing = false
    elif randf() > 0.5:
        moveDir = 1
    else:
        moveDir = -1
    _sync_move_dir = moveDir
    changeLineTween = parent.create_tween()
    changeLineTween.set_parallel(true)
    changeLineTween.tween_property(parent, ^"global_position:y", parent.global_position.y + mapGridSize.y * moveDir, 1.0)
    changeLineTween.tween_property(parent.shadowComponent, ^"saveShadowPosition:y", parent.shadowComponent.saveShadowPosition.y + mapGridSize.y * moveDir, 1.0)
    if parent.inWater:
        var viewport: Viewport = parent.get_viewport()
        var vt: Transform2D = viewport.get_screen_transform()
        vt.origin = Vector2.ZERO
        var _spriteMaterial: ShaderMaterial = parent.sprite.material as ShaderMaterial
        if is_instance_valid(_spriteMaterial) && _spriteMaterial.get_shader_parameter("discardDownPos") != null:
            changeLineTween.tween_property(_spriteMaterial, "shader_parameter/discardDownPos", (vt * (parent.spriteGroup.global_position + Vector2(0, 36 + mapGridSize.y * moveDir))).y, 1.0)
    parent.gridPos.y += moveDir
    while changeLineTween != null && is_instance_valid(changeLineTween) && changeLineTween.is_valid():
        await parent.get_tree().process_frame
    changeLineTween = null
    if _changeLineCancelled:
        _changeLineCancelled = false
        parent.isChangeLine = false
        return
    parent.InWaterDiscardSet()
    parent.isChangeLine = false

func CancelChangeLine() -> void :
    _changeLineCancelled = true
    if is_instance_valid(changeLineTween):
        changeLineTween.kill()
    parent.InWaterDiscardSet()
    parent.isChangeLine = false

func SyncSerialize() -> Dictionary:
    return {
        "move_dir": _sync_move_dir, 
        "is_change_line": parent.isChangeLine, 
    }

func SyncDeserialize(_data: Dictionary) -> void :
    _sync_move_dir = _data.get("move_dir", 0)
    _sync_deserializing = true
    if _data.has("is_change_line"):
        parent.isChangeLine = _data.get("is_change_line", false)
