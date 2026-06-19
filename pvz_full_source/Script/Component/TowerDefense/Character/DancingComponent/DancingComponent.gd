
class_name DancingComponent extends ComponentBase

signal moonWalkStarted()
@warning_ignore("unused_signal")
signal moonWalkFinished()

@onready var state: StateChart = %StateChart

var parent: TowerDefenseZombie

@export var attackComponent: AttackComponent
@export var groundMoveComponent: GroundMoveComponent

@export_subgroup("DancerSetting")
@export var dancerPacketName: String = "ZombieDancer"
@export var dancerRiseDuration: float = 1.5
@export var dancerWalkSpeedScaleMultiplier: float = 1.0
@export var syncDancerAnimation: bool = true

@export_subgroup("TimeSetting")
@export var walkTimeInit: int = 4
@export var danceTimeInit: int = 2
@export var moonWalkGridDistance: float = 2.5

@export_subgroup("AnimeSetting")
@export var sprite: AdobeAnimateSprite
@export var moonWalkAnimeClip: String = "MoonWalk"
@export var moonWalkAnimeTimeScale: float = 2.0
@export var armRiseAnimeClip: String = "ArmRise"
@export var armRiseAnimeTimeScale: float = 1.0
@export var pointUpAnimeClip: String = "PointUp"
@export var pointDownAnimeClip: String = "PointDown"
@export var pointAnimeTimeScale: float = 1.0
@export var pointDownDelay: float = 0.75
@export var walkAnimeClip: String = "Walk"
@export var dieAnimeTimeScale: float = 2.0

@export_subgroup("SpriteScaleSetting")
@export var moonWalkSpriteScaleX: float = -1.0
@export var normalSpriteScaleX: float = 1.0
@export var danceSpriteScaleX: float = -1.0
@export var armRiseFlipSprite: bool = true

@export_subgroup("SpotlightSetting")
@export var spotlight: Sprite2D
@export var spotlight2: Sprite2D
@export var spotlightGrandient: Gradient
@export var spotlightChangeInterval: float = 3.0
@export var spotlightAudioName: String = "Dancer"

var moonWalkOver: bool = false
var moonWalkMode: bool = false
var savePos: Vector2

var walkTime: int = 4
var danceTime: int = 2

var dancerList: Array[TowerDefenseCharacter] = []

var firstSpawn: bool = false

func GetName() -> String:
    return "DancingComponent"

func _ready() -> void :
    parent = get_parent().parent as TowerDefenseZombie
    if !is_instance_valid(parent):
        return
    dancerList.resize(4)
    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)
        sprite.animeEvent.connect(AnimeEvent)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return



func MoonWalkEntered() -> void :
    groundMoveComponent.alive = true
    sprite.SetAnimation(moonWalkAnimeClip, true, 0.2)
    sprite.scale.x = moonWalkSpriteScaleX
    if parent.global_position.x < TowerDefenseManager.GetMapGroundRight():
        moonWalkMode = true
        savePos = parent.global_position
    moonWalkStarted.emit()

@warning_ignore("unused_parameter")
func MoonWalkProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * moonWalkAnimeTimeScale
    if moonWalkMode:
        if abs(parent.global_position.x - savePos.x) > TowerDefenseManager.GetMapGridSize().x * moonWalkGridDistance:
            moonWalkOver = true
            state.send_event("ToPoint")
            return
    else:
        if parent.global_position.x < TowerDefenseManager.GetMapGroundRight() - TowerDefenseManager.GetMapGridSize().x * moonWalkGridDistance:
            moonWalkOver = true
            state.send_event("ToPoint")
            return
    if attackComponent.CanAttack():
        moonWalkOver = true
        state.send_event("ToPoint")
        return

func MoonWalkExited() -> void :
    groundMoveComponent.alive = false
    sprite.scale.x = normalSpriteScaleX





func DanceEntered() -> void :
    danceTime = danceTimeInit
    sprite.scale.x = danceSpriteScaleX
    sprite.SetAnimation(armRiseAnimeClip, true, 0.2)

@warning_ignore("unused_parameter")
func DanceProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * armRiseAnimeTimeScale
    if !sprite.pause && attackComponent.CanAttack():
        parent.Attack()

func DanceExited() -> void :
    sprite.scale.x = normalSpriteScaleX





func PointEntered() -> void :
    moonWalkOver = true
    sprite.SetAnimation(pointUpAnimeClip, false, 0.2)
    sprite.AddAnimation(pointDownAnimeClip, pointDownDelay, false, 0.2)

@warning_ignore("unused_parameter")
func PointProcessing(delta: float) -> void :
    sprite.timeScale = parent.timeScale * pointAnimeTimeScale

func PointExited() -> void :
    pass





func OnWalk() -> bool:
    if !moonWalkOver:
        parent.Component()
        state.send_event("ToMoonWalk")
        return true
    return false

func OnWalkEntered() -> void :
    sprite.scale.x = normalSpriteScaleX
    if syncDancerAnimation:
        for dancer: TowerDefenseCharacter in dancerList:
            if is_instance_valid(dancer):
                dancer.timeScale = parent.timeScale
                dancer.walkSpeedScale = parent.walkSpeedScale * dancerWalkSpeedScaleMultiplier
    walkTime = walkTimeInit

func CanWalk() -> bool:
    if !syncDancerAnimation:
        return true
    for dancer: TowerDefenseCharacter in dancerList:
        if is_instance_valid(dancer):
            if !dancer.die && !dancer.nearDie:
                if dancer.sprite.clip != walkAnimeClip:
                    return false
    return true

@warning_ignore("unused_parameter")
func OnAttackProcessing(delta: float) -> void :
    groundMoveComponent.alive = false

func OnDieProcessing() -> void :
    sprite.timeScale = parent.timeScale * dieAnimeTimeScale

func OnHypnoses() -> void :
    for dancer: TowerDefenseCharacter in dancerList:
        if is_instance_valid(dancer):
            dancer.jackson = null
    dancerList.clear()
    dancerList.resize(4)





func AnimeCompleted(clip: String) -> void :
    if !alive:
        return
    if parent.isShow:
        return
    if !parent.inGame:
        return
    match clip:
        pointDownAnimeClip:
            if syncDancerAnimation:
                for dancer: TowerDefenseCharacter in dancerList:
                    if is_instance_valid(dancer):
                        if !dancer.die && !dancer.nearDie:
                            dancer.Walk()
            parent.Walk()
            state.send_event("ToIdle")
        walkAnimeClip:
            walkTime -= 1
            if !parent.die && !parent.nearDie:
                if walkTime <= 0:
                    if CanSpawnDancer():
                        parent.Component()
                        state.send_event("ToPoint")
                        return
                    else:
                        if syncDancerAnimation:
                            for dancer: TowerDefenseCharacter in dancerList:
                                if is_instance_valid(dancer):
                                    if !dancer.die && !dancer.nearDie:
                                        if dancer.sprite.clip == walkAnimeClip:
                                            dancer.state.send_event("ToDance")
                        parent.Component()
                        state.send_event("ToDance")
                        return
            else:
                parent.Die()
        armRiseAnimeClip:
            if armRiseFlipSprite:
                sprite.scale.x = - sprite.scale.x
            danceTime -= 1
            if !parent.die && !parent.nearDie:
                if danceTime <= 0:
                    if CanSpawnDancer():
                        parent.Component()
                        state.send_event("ToPoint")
                        return
                    else:
                        if syncDancerAnimation:
                            for dancer: TowerDefenseCharacter in dancerList:
                                if is_instance_valid(dancer):
                                    if !dancer.die && !dancer.nearDie:
                                        if dancer.sprite.clip == armRiseAnimeClip:
                                            dancer.Walk()
                        parent.Walk()
                        state.send_event("ToIdle")
                        return
            else:
                parent.Die()

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    if !alive:
        return
    if parent.isShow:
        return
    if !parent.inGame:
        return
    match command:
        "spawn":
            if !parent.die && !parent.nearDie:
                SpawnDancer()
                if is_instance_valid(spotlight):
                    spotlight.visible = true
                if is_instance_valid(spotlight2):
                    spotlight2.visible = true
                ChangeSpotlightColor()
                if !firstSpawn:
                    firstSpawn = true
                    if spotlightAudioName != "":
                        AudioManager.AudioPlay(spotlightAudioName, AudioManagerEnum.TYPE.SFX)





func CanSpawnDancer() -> bool:
    var gridNum: Vector2 = TowerDefenseManager.GetMapGridNum()
    if parent.gridPos.y > 1:
        if !is_instance_valid(dancerList[0]):
            return true
    if parent.gridPos.y < gridNum.y:
        if !is_instance_valid(dancerList[1]):
            return true
    if !is_instance_valid(dancerList[2]):
        return true
    if !is_instance_valid(dancerList[3]):
        return true
    return false

func RemoveDancer(dancer: TowerDefenseCharacter) -> void :
    var pos = dancerList.find(dancer)
    if pos != -1:
        dancerList[pos] = null

func SpawnDancer() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(dancerPacketName)
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var _hitpointScale: float = parent.instance.hitpointScale
    var _scale: Vector2 = parent.transformPoint.scale
    if parent.gridPos.y > 1:
        if !is_instance_valid(dancerList[0]):
            var dancer = _spawn_single_dancer(packetConfig, Vector2(parent.global_position.x, TowerDefenseManager.GetMapLineY(parent.gridPos.y - 1)), parent.gridPos - Vector2i(0, 1), _hitpointScale, _scale)
            dancerList[0] = dancer
    if parent.gridPos.y < gridNum.y:
        if !is_instance_valid(dancerList[1]):
            var dancer = _spawn_single_dancer(packetConfig, Vector2(parent.global_position.x, TowerDefenseManager.GetMapLineY(parent.gridPos.y + 1)), parent.gridPos + Vector2i(0, 1), _hitpointScale, _scale)
            dancerList[1] = dancer
    if !is_instance_valid(dancerList[2]):
        var dancer = _spawn_single_dancer(packetConfig, parent.global_position - Vector2(gridSize.x * 1.25, 0), parent.gridPos - Vector2i(1, 0), _hitpointScale, _scale)
        dancerList[2] = dancer
    if !is_instance_valid(dancerList[3]):
        var dancer = _spawn_single_dancer(packetConfig, parent.global_position + Vector2(gridSize.x * 1.25, 0), parent.gridPos + Vector2i(1, 0), _hitpointScale, _scale)
        dancerList[3] = dancer

func _spawn_single_dancer(packetConfig: TowerDefensePacketConfig, pos: Vector2, gridPos: Vector2i, hitpointScale: float, scaleVal: Vector2) -> TowerDefenseCharacter:
    var dancer = packetConfig.Create(pos, gridPos, 0)
    TowerDefenseCharacter.characterNode.add_child.call_deferred(dancer)
    ( func():
        if is_instance_valid(dancer):
            if is_instance_valid(dancer.instance):
                dancer.instance.hitpointScale = hitpointScale
            if is_instance_valid(dancer.transformPoint):
                dancer.transformPoint.scale = scaleVal).call_deferred()
    dancer.Rise.call_deferred(dancerRiseDuration)
    dancer.jackson = parent
    dancer.invisible = parent.invisible
    if parent.instance.hypnoses:
        dancer.Hypnoses.call_deferred()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, dancer)
            MultiPlayerManager.SendSpawnCharacterAt(dancerPacketName, gridPos.x, gridPos.y, _sync_id, hitpointScale, scaleVal.x, parent.instance.hypnoses, dancerRiseDuration, true, pos.x, pos.y)
    return dancer

func ChangeSpotlightColor() -> void :
    if !is_instance_valid(spotlight) || !is_instance_valid(spotlight2):
        return
    if !is_instance_valid(spotlightGrandient):
        return
    var color = spotlightGrandient.sample(randf())
    spotlight.modulate = color
    spotlight2.modulate = color
    get_tree().create_timer(spotlightChangeInterval, false).timeout.connect(ChangeSpotlightColor)



func ExportComponentSave() -> Dictionary:
    var data: Dictionary = {
        "moonWalkOver": moonWalkOver, 
        "walkTime": walkTime, 
        "danceTime": danceTime, 
        "firstSpawn": firstSpawn, 
    }
    var dancerNodeNames: Array = []
    for dancer in dancerList:
        if is_instance_valid(dancer):
            dancerNodeNames.append(dancer.name)
        else:
            dancerNodeNames.append("")
    data["dancerNodeNames"] = dancerNodeNames
    if is_instance_valid(state) and is_instance_valid(state._state):
        var rootSavedState: SavedState = SavedState.new()
        state._state._state_save(rootSavedState)
        data["stateChartSave"] = {
            "child_states": rootSavedState.child_states, 
            "pending_transition_name": rootSavedState.pending_transition_name, 
            "pending_transition_remaining_delay": rootSavedState.pending_transition_remaining_delay, 
            "pending_transition_initial_delay": rootSavedState.pending_transition_initial_delay, 
        }
    return data

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    moonWalkOver = _data.get("moonWalkOver", false)
    walkTime = _data.get("walkTime", walkTimeInit)
    danceTime = _data.get("danceTime", danceTimeInit)
    firstSpawn = _data.get("firstSpawn", false)
    if _data.has("stateChartSave") and is_instance_valid(state) and is_instance_valid(state._state):
        var stateChartSave: Dictionary = _data["stateChartSave"]
        var rootSavedState: SavedState = SavedState.new()
        rootSavedState.child_states = stateChartSave.get("child_states", {})
        rootSavedState.pending_transition_name = stateChartSave.get("pending_transition_name", "")
        rootSavedState.pending_transition_remaining_delay = stateChartSave.get("pending_transition_remaining_delay", 0.0)
        rootSavedState.pending_transition_initial_delay = stateChartSave.get("pending_transition_initial_delay", 0.0)
        state._state._state_restore(rootSavedState)
        if is_instance_valid(groundMoveComponent):
            if is_instance_valid(state._state) and state._state is CompoundState and is_instance_valid(state._state._active_state):
                match state._state._active_state.name:
                    "MoonWalk":
                        groundMoveComponent.alive = true
                    _:
                        groundMoveComponent.alive = false
    if _data.has("dancerNodeNames"):
        var dancerNodeNames: Array = _data["dancerNodeNames"]
        _restore_dancer_references.call_deferred(dancerNodeNames, _owner)

func _restore_dancer_references(dancerNodeNames: Array, _owner: TowerDefenseLevelSaveConfig) -> void :
    if !is_instance_valid(parent):
        return
    for i in range(min(dancerNodeNames.size(), dancerList.size())):
        var nodeName: String = dancerNodeNames[i]
        if nodeName == "":
            continue
        if _owner.charcterDicionary.has(StringName(nodeName)):
            var dancer: TowerDefenseCharacter = _owner.charcterDicionary[StringName(nodeName)]
            if is_instance_valid(dancer):
                dancerList[i] = dancer
                if "jackson" in dancer:
                    dancer.jackson = parent



func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "moonWalkOver": moonWalkOver, 
        "walkTime": walkTime, 
        "danceTime": danceTime, 
        "firstSpawn": firstSpawn, 
    }
    var dancer_sync_ids: Array = []
    for dancer in dancerList:
        if is_instance_valid(dancer):
            dancer_sync_ids.append(dancer.sync_id)
        else:
            dancer_sync_ids.append(-1)
    data["dancerSyncIds"] = dancer_sync_ids
    if is_instance_valid(state) and is_instance_valid(state._state) and state._state is CompoundState and is_instance_valid(state._state._active_state):
        data["state"] = state._state._active_state.name
    return data

func SyncDeserialize(data: Dictionary) -> void :
    moonWalkOver = data.get("moonWalkOver", false)
    walkTime = data.get("walkTime", walkTimeInit)
    danceTime = data.get("danceTime", danceTimeInit)
    firstSpawn = data.get("firstSpawn", false)
    if data.has("dancerSyncIds") and is_instance_valid(TowerDefenseManager.currentControl):
        var ctrl = TowerDefenseManager.currentControl
        var dancer_sync_ids: Array = data["dancerSyncIds"]
        for i in range(min(dancer_sync_ids.size(), dancerList.size())):
            var sid: int = dancer_sync_ids[i]
            if sid >= 0 and ctrl._sync_characters.has(sid):
                dancerList[i] = ctrl._sync_characters[sid]
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
