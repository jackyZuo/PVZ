class_name ThrowImpComponent extends ComponentBase

var parent: TowerDefenseZombieGargantuarBase

var _sync_land_pos_x: float = 0.0
var _sync_deserializing: bool = false

func GetName() -> String:
    return "ThrowImpComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func ImpSpawn() -> void :
    if parent.isShow:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        parent.impSpawnSlot.Update()
        return
    parent.impSpawnSlot.Update()
    var impConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(parent.impName)
    var height: float = parent.GetGroundHeight(parent.impSpawnSlot.global_position.y) - parent.groundHeight
    var spawn_pos: Vector2 = Vector2(parent.impSpawnSlot.global_position.x, parent.global_position.y)
    var imp = impConfig.Create(spawn_pos, parent.gridPos, height) as TowerDefenseZombieImpBase
    imp.ySpeed = -60.0
    if imp is TowerDefenseZombieImpBase:
        imp.throw = true
    TowerDefenseGroundItemBase.characterNode.add_child(imp)
    var _hitpointScale: float = parent.instance.hitpointScale
    var _scale: Vector2 = parent.transformPoint.scale
    ( func():
        if is_instance_valid(imp):
            if is_instance_valid(imp.instance):
                imp.instance.hitpointScale = _hitpointScale
            if is_instance_valid(imp.transformPoint):
                imp.transformPoint.scale = _scale).call_deferred()
    imp.set_deferred("invisible", parent.invisible)
    if parent.instance.hypnoses:
        imp.Hypnoses()
    var landPosX: float = 0.0
    if _sync_deserializing and _sync_land_pos_x != 0.0:
        landPosX = _sync_land_pos_x
        _sync_deserializing = false
    else:
        landPosX = randf_range(TowerDefenseManager.GetMapCellPos(Vector2(3, 0)).x, TowerDefenseManager.GetMapCellPos(Vector2(5, 0)).x)
    _sync_land_pos_x = landPosX
    var tween = parent.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(imp, "global_position:x", landPosX, imp.GetFallTime())
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, imp)
            MultiPlayerManager.SendSpawnCharacterAt(parent.impName, parent.gridPos.x, parent.gridPos.y, _sync_id, _hitpointScale, _scale.x, parent.instance.hypnoses, 0.0, true, spawn_pos.x, spawn_pos.y, false, height)

func ImpFliterSet(open: bool = false) -> void :
    parent.sprite.SetFliters(parent.impFliters, open)

func SmashAttack() -> void :
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 2.0, 0.05, 4)
    AudioManager.AudioPlay("GargantuarThump", AudioManagerEnum.TYPE.SFX)
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    parent.attackComponent.SmashAttackCell(parent.config.smashAttack)

func SyncSerialize() -> Dictionary:
    return {
        "land_pos_x": _sync_land_pos_x, 
    }

func SyncDeserialize(_data: Dictionary) -> void :
    _sync_land_pos_x = _data.get("land_pos_x", 0.0)
    _sync_deserializing = true
