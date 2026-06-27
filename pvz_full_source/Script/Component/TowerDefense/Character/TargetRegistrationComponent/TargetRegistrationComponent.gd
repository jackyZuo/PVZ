
class_name TargetRegistrationComponent extends ComponentBase


@export var syncInterval: int = 5

@export var allLineCheck: bool = false

@export var canProjectileCheck: bool = true

@export var canCarry: bool = true


var parent: TowerDefenseCharacter

var targetId: int = -1

var _tdServer: Node = null

var _frameOffset: int = 0

var _dirty: bool = true

var _lastGridY: int = 0
var _lastPosX: float = 0.0
var _lastPosY: float = 0.0
var _lastCollisionFlags: int = 0
var _lastMaskFlags: int = 0
var _lastInvincible: bool = false
var _lastCanBeCollection: bool = false
var _lastDie: bool = false
var _lastNearDie: bool = false
var _lastHeight: float = 0.0
var _lastCanProjectileCheck: bool = true


func GetName() -> String:
    return "TargetRegistrationComponent"


func _ready() -> void :
    parent = get_parent().parent
    _frameOffset = randi() % syncInterval


func RegisterTarget() -> void :
    if _tdServer == null:
        _tdServer = TowerDefenseManager.GetTowerDefenseServer()
    if _tdServer == null:
        return
    targetId = _tdServer.register_target(
        parent.get_instance_id(), 
        parent.camp, 
        parent.gridPos.y, 
        parent.instance.collisionFlags, 
        parent.instance.maskFlags, 
        parent.instance.invincible, 
        parent.instance.canBeCollection, 
        parent.die, 
        parent.nearDie, 
        allLineCheck, 
        parent.instance.height, 
        parent.global_position.x, 
        parent.global_position.y, 
        parent is TowerDefenseItem, 
        parent is TowerDefenseCrater, 
        parent is TowerDefenseGravestone, 
        parent is TowerDefenseVase, 
        canProjectileCheck, 
        canProjectileCheck, 
        parent is TowerDefensePlantBowlingBase
    )
    _CacheSyncState()


func UnregisterTarget() -> void :
    if _tdServer == null || targetId < 0:
        return
    _tdServer.unregister_target(targetId)
    targetId = -1


func SyncTargetToServer() -> void :
    if _tdServer == null || targetId < 0:
        return
    _tdServer.set_target_grid_y(targetId, parent.gridPos.y)
    _tdServer.set_target_position(targetId, parent.global_position.x, parent.global_position.y)
    _tdServer.set_target_collision_flags(targetId, parent.instance.collisionFlags)
    _tdServer.set_target_mask_flags(targetId, parent.instance.maskFlags)
    _tdServer.set_target_invincible(targetId, parent.instance.invincible)
    _tdServer.set_target_can_be_collection(targetId, parent.instance.canBeCollection)
    _tdServer.set_target_die(targetId, parent.die)
    _tdServer.set_target_near_die(targetId, parent.nearDie)
    _tdServer.set_target_height(targetId, parent.instance.height)
    _tdServer.set_target_can_projectile_check(targetId, canProjectileCheck)
    _CacheSyncState()


func _CacheSyncState() -> void :
    _lastGridY = parent.gridPos.y
    _lastPosX = parent.global_position.x
    _lastPosY = parent.global_position.y
    _lastCollisionFlags = parent.instance.collisionFlags
    _lastMaskFlags = parent.instance.maskFlags
    _lastInvincible = parent.instance.invincible
    _lastCanBeCollection = parent.instance.canBeCollection
    _lastDie = parent.die
    _lastNearDie = parent.nearDie
    _lastHeight = parent.instance.height
    _lastCanProjectileCheck = canProjectileCheck


func _CheckDirty() -> bool:
    return parent.gridPos.y != _lastGridY\
|| parent.global_position.x != _lastPosX\
|| parent.global_position.y != _lastPosY\
|| parent.instance.collisionFlags != _lastCollisionFlags\
|| parent.instance.maskFlags != _lastMaskFlags\
|| parent.instance.invincible != _lastInvincible\
|| parent.instance.canBeCollection != _lastCanBeCollection\
|| parent.die != _lastDie\
|| parent.nearDie != _lastNearDie\
|| parent.instance.height != _lastHeight\
|| canProjectileCheck != _lastCanProjectileCheck


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive:
        return
    if (Engine.get_physics_frames() + _frameOffset) % syncInterval != 0:
        return
    if !_dirty && !_CheckDirty():
        return
    _dirty = false
    SyncTargetToServer()
