class_name ZombieDeathComponent extends ComponentBase

var parent: TowerDefenseZombie

var _sync_drop_velocity: Vector2 = Vector2.ZERO
var _sync_deserializing: bool = false

func GetName() -> String:
    return "ZombieDeathComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func DieEntered() -> void :
    if !parent.die:
        parent.HitpointsEmpty()
        parent.die = true
    if !parent.nearDie:
        parent.HitpointsNearDie()
        parent.nearDie = true
    if parent.dieAnimeClip != "":
        parent._dieClipArray = parent.dieAnimeClip.split("&", false)
    if parent.dieWaterAnimeClip != "":
        parent._dieWaterClipArray = parent.dieWaterAnimeClip.split("&", false)
    if parent.camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
        if GameSaveManager.GetFeatureValue("Coins"):
            var dropVelocity: Vector2 = Vector2.ZERO
            if _sync_deserializing and _sync_drop_velocity != Vector2.ZERO:
                dropVelocity = _sync_drop_velocity
                _sync_deserializing = false
            else:
                dropVelocity = Vector2(randf_range(-50.0, 50.0), -400.0)
                _sync_drop_velocity = dropVelocity
            var item = TowerDefenseManager.FallingObjectCreate(parent.global_position, parent.GetGroundHeight(parent.global_position.y), dropVelocity, 980.0)
            if item:
                item.gridPos = parent.gridPos
    if parent.inWater:
        parent.sprite.SetAnimation(parent.dieWaterAnimeClip, false, 0.2)
        if is_instance_valid(parent.duckytobeSprite):
            if is_instance_valid(parent.waterLineSprite):
                parent.waterLineSprite.visible = false
            var tween = parent.create_tween()
            tween.set_parallel(true)
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_CUBIC)
            tween.tween_property(parent, "groundHeight", -100.0, 1.0)
    else:
        parent.sprite.SetAnimation(parent.dieAnimeClip, false, 0.2)

func AnimeCompleted(clip: String) -> bool:
    if parent._dieClipArray.has(clip):
        var tween = parent.create_tween()
        tween.set_parallel(true)
        tween.tween_property(parent, "modulate:a", 0.0, 0.5)
        tween.tween_property(parent.sprite, "meshColor:a", 0.0, 0.5)
        await tween.finished
        parent.Destroy()
        return true
    elif parent._dieWaterClipArray.has(clip):
        parent.Destroy()
        return true
    return false

func SyncSerialize() -> Dictionary:
    return {
        "drop_velocity_x": _sync_drop_velocity.x, 
        "drop_velocity_y": _sync_drop_velocity.y, 
    }

func SyncDeserialize(_data: Dictionary) -> void :
    _sync_drop_velocity = Vector2(_data.get("drop_velocity_x", 0.0), _data.get("drop_velocity_y", 0.0))
    _sync_deserializing = true
