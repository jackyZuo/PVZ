
class_name SquashComponent extends ComponentBase


@onready var state: StateChart = %StateChart


@export var sprite: AdobeAnimateSprite

@export var attackComponent: AttackComponent

@export var checkArea: Area2D
@export_subgroup("Setting")

@export var hurtRange: Vector2 = Vector2(0.625, 0.2)

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

@export var checkAliveCharacter: bool = false
@export_subgroup("Anime")

@export var lookLeftAnimeClip: String = "LookLeft"

@export var lookRightAnimeClip: String = "LookRight"

@export var lookAnimeTimeScale: float = 2.0

@export var jumpUpAnimeClip: String = "JumpUp"

@export var jumpDownAnimeClip: String = "JumpDown"

@export var jumpAnimeTimeScale: float = 3.0


signal jumpDownSmash()

signal hitCharacters(charcterList: Array)

signal hitAliveCharacters(charcterList: Array)


var parent: TowerDefenseCharacter


var target: TowerDefenseCharacter

var savePos: Vector2


var over: bool = false


var running: bool = false


func GetName() -> String:
    return "SquashComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    sprite.animeCompleted.connect(AnimeCompleted)
    savePos = parent.global_position



func Execute(_target: TowerDefenseCharacter) -> void :
    if running:
        return
    running = true
    target = _target
    parent.Component()
    state.send_event("ToReady")


func IsRunning() -> bool:
    return running


func IdleEntered() -> void :
    if !alive:
        return


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !alive:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    if !running:
        if is_instance_valid(attackComponent):
            if attackComponent.CanAttack():
                Execute(attackComponent.target)


func IdleExited() -> void :
    pass


func ReadyEntered() -> void :
    AudioManager.AudioPlay("SquasHmm", AudioManagerEnum.TYPE.SFX)
    parent.instance.invincible = true
    if is_instance_valid(target):
        savePos = target.global_position
    if savePos < global_position:
        if lookLeftAnimeClip != "":
            sprite.SetAnimation(lookLeftAnimeClip, false, 0.1)
        else:
            await get_tree().create_timer(0.1, false).timeout
            state.send_event("ToJump")
    else:
        if lookRightAnimeClip != "":
            sprite.SetAnimation(lookRightAnimeClip, false, 0.1)
        else:
            await get_tree().create_timer(0.1, false).timeout
            state.send_event("ToJump")


@warning_ignore("unused_parameter")
func ReadyProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * lookAnimeTimeScale


func ReadyExited() -> void :
    pass


func JumpEntered() -> void :
    parent.destroy.emit(parent)
    parent.instance.maskFlags = 0
    parent.itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.PROJECTILE
    parent.gravity = 0.0
    if sprite.HasClip(jumpUpAnimeClip):
        sprite.SetAnimation(jumpUpAnimeClip, false, 0.2)
        await get_tree().create_timer(0.3, false).timeout
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUART)
    tween.tween_property(parent, ^"z", parent.groundHeight + 120.0, 0.4)
    tween.tween_property(parent, ^"global_position:x", savePos.x, 0.4)
    if !sprite.HasClip(jumpUpAnimeClip):
        await tween.finished
        await get_tree().create_timer(0.1, false).timeout
        parent.gridPos = TowerDefenseManager.GetMapGridPos(parent.global_position)
        if is_instance_valid(parent.cell):
            parent.groundHeight = parent.cell.GetGroundHeight()
        var downTween = create_tween()
        downTween.set_ease(Tween.EASE_OUT)
        downTween.set_trans(Tween.TRANS_EXPO)
        downTween.tween_property(parent, ^"z", parent.groundHeight, 0.1)
        JumpDownSmash()


@warning_ignore("unused_parameter")
func JumpProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * jumpAnimeTimeScale


func JumpExited() -> void :
    pass


func AnimeCompleted(clip: String) -> void :
    if clip == "":
        return
    match clip:
        jumpUpAnimeClip:
            await get_tree().create_timer(0.4, false).timeout
            parent.gridPos = TowerDefenseManager.GetMapGridPos(global_position)
            if is_instance_valid(parent.cell):
                parent.groundHeight = parent.cell.GetGroundHeight()
            sprite.SetAnimation("JumpDown", false, 0.1)
            var tween = create_tween()
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_EXPO)
            tween.tween_property(parent, ^"z", parent.groundHeight, 0.1)
        jumpDownAnimeClip:
            JumpDownSmash()
        lookLeftAnimeClip:
            await get_tree().create_timer(0.5, false).timeout
            state.send_event("ToJump")
        lookRightAnimeClip:
            await get_tree().create_timer(0.5, false).timeout
            state.send_event("ToJump")


func JumpDownSmash() -> void :
    if over:
        return
    over = true
    jumpDownSmash.emit()
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    TowerDefenseExplode.CreateExplode(parent.global_position, hurtRange, eventList, [], parent.camp, parent.instance.collisionFlags)
    parent.gridPos = TowerDefenseManager.GetMapGridPos(parent.global_position)
    if is_instance_valid(parent.cell):
        if !checkAliveCharacter && parent.cell.IsWater():
            JumpDownWater()
            return
        else:
            AudioManager.AudioPlay("GargantuarThump", AudioManagerEnum.TYPE.SFX)
    else:
        AudioManager.AudioPlay("GargantuarThump", AudioManagerEnum.TYPE.SFX)

    if is_instance_valid(checkArea):
        if is_instance_valid(attackComponent):
            hitCharacters.emit(TowerDefenseManager.GetCharacterTargetFromArea(parent, checkArea))
        if checkAliveCharacter:
            await get_tree().physics_frame
            await get_tree().physics_frame
            if is_instance_valid(attackComponent):
                hitAliveCharacters.emit(TowerDefenseManager.GetCharacterTargetFromArea(parent, checkArea))
            if is_instance_valid(parent.cell):
                if parent.cell.IsWater():
                    JumpDownWater()
                    return

    await get_tree().create_timer(0.5, false).timeout
    TowerDefenseManager.CharacterUnregister(parent)
    parent.remove_from_group("Character")
    parent.queue_free()


func JumpDownWater() -> void :
    parent.CreateSplash()
    AudioManager.AudioPlay("PlantWater", AudioManagerEnum.TYPE.SFX)
    TowerDefenseManager.CharacterUnregister(parent)
    parent.remove_from_group("Character")
    parent.queue_free()

func ExportComponentSave() -> Dictionary:
    var data: Dictionary = {
        "savePos": savePos, 
        "over": over, 
        "running": running, 
    }
    if is_instance_valid(target):
        data["target"] = target.name.validate_node_name()
    return data

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    savePos = _data.get("savePos", Vector2.ZERO)
    over = _data.get("over", false)
    running = _data.get("running", false)
    var targetName: String = _data.get("target", "")
    if targetName != "" and _owner.charcterDicionary.has(targetName):
        target = _owner.charcterDicionary[targetName]

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "over": over, 
        "running": running, 
        "savePosX": savePos.x, 
        "savePosY": savePos.y, 
    }
    if is_instance_valid(target):
        data["targetSyncId"] = target.sync_id
    if is_instance_valid(state) and is_instance_valid(state._state) and state._state is CompoundState and is_instance_valid(state._state._active_state):
        data["state"] = state._state._active_state.name
    return data

func SyncDeserialize(data: Dictionary) -> void :
    over = data.get("over", false)
    running = data.get("running", false)
    savePos = Vector2(data.get("savePosX", 0.0), data.get("savePosY", 0.0))
    if data.has("targetSyncId"):
        var target_sync_id: int = data["targetSyncId"]
        if target_sync_id >= 0 and is_instance_valid(TowerDefenseManager.currentControl):
            var ctrl = TowerDefenseManager.currentControl
            if ctrl._sync_characters.has(target_sync_id):
                target = ctrl._sync_characters[target_sync_id]
    if data.has("state"):
        _sync_force_state(data["state"])

func _sync_force_state(target_state: String) -> void :
    if !is_instance_valid(state) or !is_instance_valid(state._state):
        return
    if !(state._state is CompoundState) or !is_instance_valid(state._state._active_state):
        return
    if state._state._active_state.name == target_state:
        return
    state.send_event("To" + target_state)
