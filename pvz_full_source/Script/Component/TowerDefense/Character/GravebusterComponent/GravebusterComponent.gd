
class_name GravebusterComponent extends ComponentBase


signal over()


@onready var state: StateChart = %StateChart

@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var landAnimeClips: String = "Land"

@export var landAnimeTimeScale: float = 1.0

@export var gravebusterAnimeClips: String = "Idle"

@export var gravebusterTimeScale: float = 1.0


var parent: TowerDefenseCharacter


var graveStone: TowerDefenseGravestone


var graveStoneTween: Tween

var _sync_drop_velocity: Vector2 = Vector2.ZERO
var _sync_deserializing: bool = false


func GetName() -> String:
    return "GravebusterComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return

    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)

    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(parent.gridPos)
    await get_tree().physics_frame
    if is_instance_valid(cell):
        graveStone = cell.FindSlotParent(parent)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return




func _exit_tree() -> void :
    if is_instance_valid(graveStone):
        if is_instance_valid(graveStoneTween):
            graveStoneTween.kill()
        graveStone.SetSpriteGroupShaderParameter("discardUpPos", -10000)


func IdleEntered() -> void :
    if parent.componentRunning:
        parent.Idle()


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    parent.Component()
    state.send_event("ToGravebuster")


func IdleExited() -> void :
    pass


func GravebusterEntered() -> void :
    if landAnimeClips != "":
        sprite.SetAnimation(landAnimeClips, false, 0.2)
        sprite.AddAnimation(gravebusterAnimeClips, 0.0, true, 0.0)
    else:
        StartGravebuster()
    sprite.position.y = -70


@warning_ignore("unused_parameter")
func GravebusterProcessing(delta: float) -> void :
    if !alive || !parent.componentAlive:
        state.send_event("ToIdle")
    match sprite.clip:
        landAnimeClips:
            sprite.timeScale = parent.timeScale * landAnimeTimeScale
        gravebusterAnimeClips:
            sprite.timeScale = parent.timeScale * gravebusterTimeScale


func GravebusterExited() -> void :
    pass



func AnimeCompleted(clip: String) -> void :
    match clip:
        landAnimeClips:
            StartGravebuster()


func StartGravebuster() -> void :
    var viewport: Viewport = get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    AudioManager.AudioPlay("GraveBusterChomp", AudioManagerEnum.TYPE.SFX)
    if is_instance_valid(graveStone):
        graveStone.SetSpriteGroupShaderParameter("discardUpPos", (vt * (parent.spriteGroup.global_position + Vector2(0, -30))).y)
    graveStoneTween = create_tween()
    graveStoneTween.set_parallel(true)
    graveStoneTween.tween_property(sprite, ^"position:y", -30, 5.0)
    if is_instance_valid(graveStone):
        graveStoneTween.tween_property(graveStone.sprite.material, ^"shader_parameter/discardUpPos", (vt * (parent.spriteGroup.global_position + Vector2(0, 0))).y, 5.0)
    await graveStoneTween.finished
    if GameSaveManager.GetFeatureValue("Coins"):
        var dropVelocity: Vector2 = Vector2(randf_range(-50.0, 50.0), -400.0)
        if _sync_deserializing and _sync_drop_velocity != Vector2.ZERO:
            dropVelocity = _sync_drop_velocity
            _sync_drop_velocity = Vector2.ZERO
            _sync_deserializing = false
        else:
            _sync_drop_velocity = dropVelocity
        var item = TowerDefenseManager.FallingObjectCreate(global_position, parent.GetGroundHeight(global_position.y), dropVelocity, 980.0)
        if item:
            item.gridPos = parent.gridPos
    if is_instance_valid(graveStone):
        graveStone.Destroy()
    Over()


func Over() -> void :
    over.emit()
    parent.Destroy()

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {}
    if _sync_drop_velocity != Vector2.ZERO:
        data["drop_velocity_x"] = _sync_drop_velocity.x
        data["drop_velocity_y"] = _sync_drop_velocity.y
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("drop_velocity_x"):
        _sync_drop_velocity = Vector2(_data.get("drop_velocity_x", 0.0), _data.get("drop_velocity_y", 0.0))
        _sync_deserializing = true
