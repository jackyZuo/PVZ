class_name TowerDefenseControlNew extends TowerDefenseControl

@warning_ignore("unused_signal")
signal viewBack()

@onready var state: StateChart = %State
@onready var levelControl: TowerDefenseInGameLevelControl = %TowerDefenseInGameLevelControl
@onready var characterCanvasModulate: CanvasModulate = %CharacterCanvasModulate
@onready var characterNode: Node2D = %CharacterNode
@onready var bankUILayer: CanvasLayer = %BankUILayer
@onready var uITopBankContainer: HBoxContainer = %UITopBankContainer
@onready var uITopPropContainer: HBoxContainer = %UITopPropContainer
@onready var mobileInterval: Control = %MobileInterval

@onready var uiTopAnimationPlayer: AnimationPlayer = %UITopAnimationPlayer

var uilayerDictionary: Dictionary[int, CanvasLayer]
var layerDictionary: Dictionary[int, CanvasLayer]
var featureDictionary: Dictionary[StringName, TowerDefenseBattleFeature]
var process: TowerDefenseBattleProcess
var changeCostList: Array[TowerDefensePacketChangeCost] = []

func ChangeCostAdd(changeCost: TowerDefensePacketChangeCost) -> bool:
    if changeCost.key != "":
        for existing: TowerDefensePacketChangeCost in changeCostList:
            if existing.key == changeCost.key:
                return false
    changeCostList.append(changeCost)
    return true

func ChangeCostRemove(changeCost: TowerDefensePacketChangeCost) -> bool:
    var idx: int = changeCostList.find(changeCost)
    if idx == -1:
        return false
    changeCostList.remove_at(idx)
    return true

@onready var zombieWon: TowerDefenseZombieWon = %TowerDefenseZombieWon
@onready var zombieCheckArea: Area2D = %ZombieCheckArea

var isGameRunning: bool = false
var isGameFail: bool = false
var isInit: bool = true
var failCharacter: TowerDefenseCharacter
var waitPause: bool = false
var isView: bool = false

var _sync_timer: float = 0.0
const SYNC_INTERVAL: float = 0.5
var _character_sync_timer: float = 0.0
const CHARACTER_SYNC_INTERVAL: float = 1.0
var _plant_full_sync_timer: float = 0.0
const PLANT_FULL_SYNC_INTERVAL: float = 5.0
var _zombie_sync_timer: float = 0.0
const ZOMBIE_SYNC_INTERVAL: float = 0.2
const ZOMBIE_SYNC_BATCH_SIZE: int = 40
var _pending_destroy_sync_ids: Dictionary = {}
var _pending_destroy_cleanup_timer: float = 0.0
const PENDING_DESTROY_TIMEOUT: float = 10.0
var _zombie_sync_miss_count: Dictionary = {}
var _zombie_sync_keys: Array = []
var _zombie_sync_batch_index: int = 0
var _cursor_sync_timer: float = 0.0
const CURSOR_SYNC_INTERVAL: float = 0.1
var _sync_id_counter: int = 0
var _sync_characters: Dictionary = {}
var _packet_sync_id_counter: int = 0
var _sync_packets: Dictionary = {}
var _is_multiplayer_paused: bool = false
var _zombie_target_positions: Dictionary = {}
var _zombie_last_sync_state: Dictionary = {}
var _zombie_sync_velocities: Dictionary = {}
var _zombie_last_sync_time: Dictionary = {}
var _last_pick_type: String = ""
var _last_pick_name: String = ""
var _remote_cursors: Dictionary = {}
var _choose_ready_peers: Array = []
var _choose_over_received: bool = false
signal _all_choose_ready
var _choose_wait_label: RichTextLabel = null
var _player_status_panel: Control = null

const PLAYER_COLORS: Array[Color] = [
    Color(0.3, 0.7, 1.0), 
    Color(1.0, 0.5, 0.3), 
    Color(0.5, 1.0, 0.5), 
    Color(1.0, 1.0, 0.3), 
]

func _ready() -> void :
    super._ready()
    TowerDefenseBattleRegistry.Init()
    TowerDefenseManager.pausePacket = false
    TowerDefenseManager.pauseZombie = false
    TowerDefenseManager.backPacket = false
    TowerDefenseManager.backZombie = false
    TowerDefenseManager.deathList.clear()
    TowerDefenseManager.luckyBagNum = 0
    DropItemRegistry.Reset()
    BattleEventBus.uiSwitched.connect(UISwitched)
    BattleEventBus.packetUIFront.connect(PacketUIFront)
    SceneManager.sceneChange.connect(_on_scene_change)
    if is_instance_valid(TowerDefenseManager.currentLevelConfig):
        Init(TowerDefenseManager.currentLevelConfig)
    UISwitched(GameSaveManager.GetConfigValue("MobilePreset"))
    await get_tree().physics_frame
    state.send_event("ToGameInit")

func Init(_levelConfig: TowerDefenseLevelBaseConfig):
    super.Init(_levelConfig)
    Global.timeScale = levelConfig.baseTimeScale
    if levelConfig.name != "":
        if !Global.isMultiplayerMode and GameSaveManager.HasLevelProgress(levelConfig.name):
            hasProgress = true
        if !Global.isMultiplayerMode:
            var levelData: Dictionary = GameSaveManager.GetLevelValue(levelConfig.name)
            var playNum = levelData.get_or_add("Key", {}).get_or_add("Play", 0)
            levelData["Key"]["Play"] = playNum + 1
            GameSaveManager.SetLevelValue(levelConfig.name, levelData)
            GameSaveManager.Save()
    if levelConfig is TowerDefenseLevelConfig:
        OldLevelInit(levelConfig)
    elif levelConfig is TowerDefenseLevelNewConfig:
        NewLevelInit(levelConfig)

    if CommandManager.debugOpenGlove:
        AddFeature("Glove", {})

    if Global.isMultiplayerMode:
        MultiPlayerManager.match_state_received.connect(_on_multiplayer_state_received)
        MultiPlayerManager.peer_left.connect(_on_multiplayer_peer_left)
        BattleEventBus.gameVictory.connect(_on_multiplayer_victory)
        BattleEventBus.gameFailed.connect(_on_multiplayer_failed)
        _init_player_status_panel()



func OldLevelInit(_levelConfig: TowerDefenseLevelConfig) -> void :
    for featureName: StringName in _levelConfig.featureData:
        AddFeature(featureName, _levelConfig.featureData[featureName])

    if _levelConfig.processName != &"":
        SetProcess(_levelConfig.processName, _levelConfig.processData)
        if _levelConfig.finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2 && process is TowerDefenseBattleProcessWave:
            process.isIZM2 = true

    AddProcessDependenceFeature()

    for feature: TowerDefenseBattleFeature in featureDictionary.values():
        feature.Ready()

    process.Ready()

    levelControl.Init(_levelConfig)

func NewLevelInit(_levelConfig: TowerDefenseLevelNewConfig) -> void :
    for featureName: StringName in _levelConfig.featureData:
        AddFeature(featureName, _levelConfig.featureData[featureName])

    if _levelConfig.processName != &"":
        SetProcess(_levelConfig.processName, _levelConfig.processData)

    AddProcessDependenceFeature()

    for feature: TowerDefenseBattleFeature in featureDictionary.values():
        feature.Ready()

    if process:
        process.Ready()





func AddFeature(featureName: StringName, data: Dictionary) -> void :
    var feature: TowerDefenseBattleFeature = TowerDefenseBattleRegistry.GetFeature(featureName)
    feature.control = self
    feature.Init(data)
    if is_instance_valid(feature):
        featureDictionary[featureName] = feature

func AddProcessDependenceFeature() -> void :
    if !process || !process.dependenceData:
        return
    for featureName: StringName in process.dependenceData.featureNames:
        if !featureDictionary.has(featureName):
            if levelConfig is TowerDefenseLevelConfig:
                var method: TowerDefenseEnum.LEVEL_SEEDBANK_METHOD = levelConfig.packetBankMethod
                if featureName == "PacketBank" && method != TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET && method != TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE:
                    continue
                if featureName == "SeedBank" && method != TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET && method != TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE && method != TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
                    continue
            AddFeature(featureName, {})

func ZombieWonLevelFail(playAnime: bool = true) -> void :
    if is_instance_valid(zombieWon):
        zombieWon.LevelFail(playAnime)

func GetFeature(featureName: StringName) -> TowerDefenseBattleFeature:
    if !featureDictionary.has(featureName):
        return null
    return featureDictionary[featureName]

func RemoveFeature(featureName: StringName) -> void :
    if !featureDictionary.has(featureName):
        return
    var feature: TowerDefenseBattleFeature = featureDictionary[featureName]
    feature.Destroy()
    featureDictionary.erase(featureName)





func SetProcess(processName: StringName, data: Dictionary = {}) -> void :
    process = TowerDefenseBattleRegistry.GetProcess(processName)
    if process:
        process.control = self
        process.Init(data)





func AddNode(node: Node, layerId: int = -1) -> void :
    if !layerDictionary.has(layerId):
        var newLayer: CanvasLayer = CanvasLayer.new()
        newLayer.layer = layerId
        newLayer.follow_viewport_enabled = true
        add_child(newLayer)
        layerDictionary[layerId] = newLayer
    var layer: CanvasLayer = layerDictionary[layerId]
    layer.add_child(node)

func AddUI(node: Node, layerId: int) -> void :
    if !uilayerDictionary.has(layerId):
        var newLayer: CanvasLayer = CanvasLayer.new()
        newLayer.layer = layerId
        newLayer.follow_viewport_enabled = false
        add_child(newLayer)
        uilayerDictionary[layerId] = newLayer
    var layer: CanvasLayer = uilayerDictionary[layerId]
    layer.add_child(node)

func MoveUI(node: Node, layerId: int) -> void :
    if !uilayerDictionary.has(layerId):
        var newLayer: CanvasLayer = CanvasLayer.new()
        newLayer.layer = layerId
        newLayer.follow_viewport_enabled = false
        add_child(newLayer)
        uilayerDictionary[layerId] = newLayer
    var layer: CanvasLayer = uilayerDictionary[layerId]
    node.reparent(layer)

func AddUIToTopBankContainer(node: Node) -> void :
    uITopBankContainer.add_child(node)

func AddUIToTopPropContainer(node: Node) -> void :
    uITopPropContainer.add_child(node)





@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if isGameRunning:
        TowerDefenseManager.runGameTime += delta
        if !waitPause:
            if !Global.isMultiplayerMode && (Input.is_action_just_pressed("Pause") || ( !GameSaveManager.GetConfigValue("Backgrounder") && !DisplayServer.window_is_focused())):
                AudioManager.AudioPlay("Pause", AudioManagerEnum.TYPE.SFX, 0.0, true, true)
                DialogManager.DialogCreate("Pause")
                waitPause = true
                await get_tree().create_timer(0.1, false).timeout
                waitPause = false
            elif Global.isMultiplayerMode and Input.is_action_just_pressed("Pause") and !_is_multiplayer_paused:
                MultiPlayerManager.SendPause()

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if process:
        process.InputProcess(event)
    if Input.is_action_just_pressed("SpeedUp") and !Global.isMultiplayerMode:
        checkBox2X.button_pressed = !checkBox2X.button_pressed
    if Input.is_action_just_pressed("PacketUIFront"):
        GameSaveManager.SetConfigValue("PacketUIFront", !GameSaveManager.GetConfigValue("PacketUIFront"))
        BattleEventBus.packetUIFront.emit(GameSaveManager.GetConfigValue("PacketUIFront"))
        GameSaveManager.SaveGameConfig()
    if Input.is_action_just_pressed("ShowPlantHealth"):
        GameSaveManager.SetConfigValue("ShowPlantHealth", !GameSaveManager.GetConfigValue("ShowPlantHealth"))
        BattleEventBus.showPlantHealth.emit(GameSaveManager.GetConfigValue("ShowPlantHealth"))
        GameSaveManager.SaveGameConfig()
    if Input.is_action_just_pressed("ShowZombieHealth"):
        GameSaveManager.SetConfigValue("ShowZombieHealth", !GameSaveManager.GetConfigValue("ShowZombieHealth"))
        BattleEventBus.showZombieHealth.emit(GameSaveManager.GetConfigValue("ShowZombieHealth"))
        GameSaveManager.SaveGameConfig()
    if Global.isMultiplayerMode and is_instance_valid(_player_status_panel):
        if Input.is_action_pressed("ShowPlayerStatus"):
            _player_status_panel.ShowPanel()
        else:
            _player_status_panel.HidePanel()





func GameInitEntered() -> void :
    if hasProgress:
        for feature in featureDictionary.values():
            if feature.CanLoadProgress():
                await feature.GameInitFromProgress()
            else:
                await feature.GameInit()
        if process:
            if process.CanLoadProgress():
                @warning_ignore("redundant_await")
                await process.GameInitFromProgress()
            else:
                @warning_ignore("redundant_await")
                await process.GameInit()
        GameSaveManager.LoadLevelProgress(levelConfig.name)

    else:
        for feature in featureDictionary.values():
            await feature.GameInit()
        if process:
            @warning_ignore("redundant_await")
            await process.GameInit()
    state.send_event("ToGameEntry")

func GameEntryEntered() -> void :
    isGameRunning = false
    if Global.isMultiplayerMode and MultiPlayerManager.isHost and MultiPlayerManager._game_entry_sent:
        MultiPlayerManager.ResetGameEntryAck()
        if !MultiPlayerManager.CheckAllGameEntryAcked():
            await MultiPlayerManager.all_game_entry_acked
    for feature in featureDictionary.values():
        await feature.GameEntry()
    if process:
        @warning_ignore("redundant_await")
        await process.GameEntry()
    if !isInit:
        levelControl.awardCreate = false
    state.send_event("ToGameReady")

func GameEntryExited() -> void :
    pass

func GameReadyEntered() -> void :
    if Global.isMultiplayerMode:
        if !_choose_ready_peers.has(MultiPlayerManager.peerId):
            _choose_ready_peers.append(MultiPlayerManager.peerId)
        _show_choose_wait_label()
        MultiPlayerManager.SendChooseReady()
        MultiPlayerManager.ResetClientsReady()
        if MultiPlayerManager.isHost and !_choose_over_received:
            var all_ready: bool = true
            for member_id: String in MultiPlayerManager.matchMembers:
                if !_choose_ready_peers.has(member_id):
                    all_ready = false
                    break
            if all_ready:
                MultiPlayerManager.SendChooseOver()
                _do_choose_over()
        if !_choose_over_received:
            await _all_choose_ready
        _hide_choose_wait_label()
    for feature in featureDictionary.values():
        await feature.GameReady()
    if process:
        @warning_ignore("redundant_await")
        await process.GameReady()
    state.send_event("ToGameRunning")

func GameReadyExited() -> void :
    pass

func GameRunningEntered() -> void :
    isGameRunning = true
    isInit = false
    if Global.isMultiplayerMode:
        _choose_ready_peers.clear()
        _choose_over_received = false
    if levelConfig is TowerDefenseLevelConfig and levelConfig.finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.QUIZ:
        isGameRunning = false
    buttonPause.visible = true
    optionButton.visible = true
    if Global.isMultiplayerMode:
        checkBox2X.visible = false
        if checkBox2X.button_pressed:
            checkBox2X.button_pressed = false
    else:
        checkBox2X.visible = true
    for character in TowerDefenseManager.GetCharacter():
        character.state.process_mode = Node.PROCESS_MODE_INHERIT
    for zombie in TowerDefenseManager.GetZombie():
        zombie.call("Walk")
    if hasProgress:
        for feature in featureDictionary.values():
            if feature.CanLoadProgress():
                await feature.GameStartFromProgress()
            else:
                await feature.GameStart()
        if process:
            if process.CanLoadProgress():
                @warning_ignore("redundant_await")
                await process.GameStartFromProgress()
            else:
                @warning_ignore("redundant_await")
                await process.GameStart()
        DialogManager.DialogCreate("Pause")
        hasProgress = false
    else:
        for feature in featureDictionary.values():
            await feature.GameStart()
        if process:
            @warning_ignore("redundant_await")
            await process.GameStart()

func GameRunningExited() -> void :
    isGameRunning = false

func GameRunningProcessing(delta: float) -> void :
    for feature in featureDictionary.values():
        feature.Process(delta)
    if process:
        process.PhysicsProcess(delta)
    if Global.isMultiplayerMode and MultiPlayerManager.IsConnect():
        for feature in featureDictionary.values():
            feature.SyncProcess(delta)
        if process:
            process.SyncProcess(delta)
        if MultiPlayerManager.isHost:
            _sync_timer += delta
            if _sync_timer >= SYNC_INTERVAL:
                _sync_timer = 0.0
                _multiplayer_broadcast_state()
            _character_sync_timer += delta
            if _character_sync_timer >= CHARACTER_SYNC_INTERVAL:
                _character_sync_timer = 0.0
                _multiplayer_broadcast_character_state()
            _plant_full_sync_timer += delta
            if _plant_full_sync_timer >= PLANT_FULL_SYNC_INTERVAL:
                _plant_full_sync_timer = 0.0
                _multiplayer_broadcast_plant_full_sync()
            _zombie_sync_timer += delta
            if _zombie_sync_timer >= ZOMBIE_SYNC_INTERVAL:
                _zombie_sync_timer = 0.0
                _multiplayer_broadcast_zombie_state()
        else:
            _multiplayer_interpolate_zombie_positions(delta)
        _cursor_sync_timer += delta
        if _cursor_sync_timer >= CURSOR_SYNC_INTERVAL:
            _cursor_sync_timer = 0.0
            _send_cursor_sync()
        _pending_destroy_cleanup_timer += delta
        if _pending_destroy_cleanup_timer >= PENDING_DESTROY_TIMEOUT:
            _pending_destroy_cleanup_timer = 0.0
            _cleanup_pending_destroys()

func GameFailEntered() -> void :
    isGameFail = true
    isGameRunning = false
    for feature in featureDictionary.values():
        feature.GameFail()
    if process:
        process.GameFail(failCharacter)

func _on_scene_change(_sceneName: String) -> void :
    isGameRunning = false
    process_mode = Node.PROCESS_MODE_DISABLED

func TriggerGameFail(enterCharacter: TowerDefenseCharacter) -> void :
    failCharacter = enterCharacter
    state.send_event("ToGameFail")

func TriggerGameEntry() -> void :
    state.send_event("ToGameEntry")

func ReadySetPlantPlay() -> void :
    await levelControl.ReadySetPlantPlay()

func TipsPlay(text: String, duration: float = 2.0) -> void :
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        MultiPlayerManager.SendTipsPlay(text, duration)
    await levelControl.TipsPlay(text, duration)

func ViewMap() -> void :
    if process:
        process.ViewMap()

func GameFail(enterCharacter: TowerDefenseCharacter) -> void :
    failCharacter = enterCharacter
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        MultiPlayerManager.SendGameResult(false)
    for character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
        if character != enterCharacter:
            character.process_mode = Node.PROCESS_MODE_DISABLED
    state.send_event("ToGameFail")

func GameEntry() -> void :
    TriggerGameEntry()





func ZombieCheckAreaEntered(area: Area2D) -> void :
    var character = area.get_parent()
    if !(character is TowerDefenseZombie):
        return
    if character.instance.die || character.instance.nearDie:
        return
    if character.instance.hypnoses:
        return
    if character.scale.x < 0:
        return
    if process:
        process.ZombieEnterHouse(character)
    for feature in featureDictionary.values():
        feature.ZombieEnterHouse(character)

func UISwitched(shown: bool) -> void :
    if shown:
        bankUILayer.layer = 3
        mobileInterval.custom_minimum_size.x = 400
    else:
        bankUILayer.layer = 3 if GameSaveManager.GetConfigValue("PacketUIFront") else 1
        mobileInterval.custom_minimum_size.x = 0

func PacketUIFront(open: bool) -> void :
    if open:
        bankUILayer.layer = 3
    else:
        bankUILayer.layer = 3 if GameSaveManager.GetConfigValue("MobilePreset") else 1





var _game_state_last_sync: Dictionary = {}

func _init_player_status_panel() -> void :
    var gui_top: CanvasLayer = get_node_or_null("GUITop")
    if !is_instance_valid(gui_top):
        return
    var panel_scene: PackedScene = load("uid://dg77jwfvccr4t")
    _player_status_panel = panel_scene.instantiate()
    gui_top.add_child(_player_status_panel)

func _multiplayer_broadcast_state() -> void :
    var _state: Dictionary = {}
    for featureName in featureDictionary.keys():
        var feature_data = featureDictionary[featureName].SyncSerialize()
        if feature_data.size() > 0:
            var last_feature: Dictionary = _game_state_last_sync.get(featureName, {})
            if !_dict_approx_equal(feature_data, last_feature):
                _state[featureName] = feature_data
                _game_state_last_sync[featureName] = feature_data.duplicate(true)
    if process:
        var process_data = process.SyncSerialize()
        if process_data.size() > 0:
            var last_process: Dictionary = _game_state_last_sync.get("process", {})
            if !_dict_approx_equal(process_data, last_process):
                _state["process"] = process_data
                _game_state_last_sync["process"] = process_data.duplicate(true)
    if _state.size() > 0:
        MultiPlayerManager.SendMatchState(MatchOpCodes.GAME_STATE_SYNC, JSON.stringify(_state))

func _dict_approx_equal(a: Dictionary, b: Dictionary) -> bool:
    if a.size() != b.size():
        return false
    for key in a:
        if !b.has(key):
            return false
        var va = a[key]
        var vb = b[key]
        if va is Dictionary and vb is Dictionary:
            if !_dict_approx_equal(va, vb):
                return false
        elif va is Array and vb is Array:
            if va.size() != vb.size():
                return false
            for i in va.size():
                if va[i] is Dictionary and vb[i] is Dictionary:
                    if !_dict_approx_equal(va[i], vb[i]):
                        return false
                elif va[i] is float and vb[i] is float:
                    if absf(va[i] - vb[i]) > 0.05:
                        return false
                elif va[i] != vb[i]:
                    return false
        elif va is float and vb is float:
            if absf(va - vb) > 0.05:
                return false
        elif va != vb:
            return false
    return true

var _character_last_sync_state: Dictionary = {}

func _multiplayer_broadcast_character_state() -> void :
    var characters_data: Array = []
    var invalid_keys: Array = []
    for sync_id_val in _sync_characters.keys():
        var character = _sync_characters[sync_id_val]
        if !is_instance_valid(character):
            invalid_keys.append(sync_id_val)
            continue
        if character.isDestroy:
            continue
        if character is TowerDefenseZombie:
            continue
        var char_data: Dictionary = {"sync_id": sync_id_val}
        var has_change: bool = false
        var cur_clip: String = ""
        var cur_loop: bool = true
        var cur_blend: float = 0.0
        var cur_frame: int = 0
        if is_instance_valid(character.sprite):
            cur_clip = character.sprite.clip
            cur_loop = character.sprite.loop
            cur_blend = character.sprite.blendTime
            cur_frame = character.sprite.frameIndex
        var last: Dictionary = _character_last_sync_state.get(sync_id_val, {})
        if cur_clip != last.get("clip", "") or cur_loop != last.get("loop", true) or absf(cur_blend - last.get("blendTime", 0.0)) > 0.01:
            char_data["clip"] = cur_clip
            if !cur_loop:
                char_data["loop"] = false
            if cur_blend > 0.01:
                char_data["blendTime"] = snappedf(cur_blend, 0.01)
            char_data["frame"] = cur_frame
            has_change = true
        elif absi(cur_frame - last.get("frame", 0)) > 3:
            char_data["clip"] = cur_clip
            char_data["frame"] = cur_frame
            has_change = true
        if is_instance_valid(character.componentManager):
            var components_data: Dictionary = {}
            for component in character.componentManager.componentList:
                if is_instance_valid(component) and component.has_method("SyncSerialize"):
                    var comp_data: Dictionary = component.SyncSerialize()
                    if comp_data.size() > 0:
                        components_data[component.GetName()] = comp_data
            if components_data.size() > 0:
                char_data["components"] = components_data
                has_change = true
        if is_instance_valid(character.instance) and character.instance.damagePointData:
            var cur_dpi: int = character.instance.damagePointIndex
            var last_dpi: int = _character_last_sync_state.get(sync_id_val, {}).get("dpi", 0)
            if cur_dpi != last_dpi:
                char_data["dpi"] = cur_dpi
                has_change = true
        if is_instance_valid(character.instance):
            var cur_hp: float = character.instance.hitpoints
            var last_hp: float = _character_last_sync_state.get(sync_id_val, {}).get("hp", cur_hp)
            if absf(cur_hp - last_hp) > 1.0:
                char_data["hp"] = snappedf(cur_hp, 0.1)
                has_change = true
        if is_instance_valid(character.instance) and character.instance.armorList.size() > 0:
            var armors_data: Array = []
            var last_armors: Array = last.get("ar", [])
            var armor_changed: bool = false
            for ai in character.instance.armorList.size():
                var armor: TowerDefenseArmorInstance = character.instance.armorList[ai]
                if !is_instance_valid(armor):
                    continue
                if armor.isRemove:
                    var was_present: bool = false
                    for la in last_armors:
                        if la.get("i", -1) == ai and !la.get("rm", false):
                            was_present = true
                            break
                    if was_present or last_armors.is_empty():
                        armors_data.append({"i": ai, "rm": true})
                        armor_changed = true
                    continue
                var a_data: Dictionary = {"i": ai, "hp": snappedf(armor.hitPoints, 0.1), "si": armor.stageIndex}
                armors_data.append(a_data)
                if ai < last_armors.size():
                    if absf(armor.hitPoints - last_armors[ai].get("hp", 0.0)) > 1.0 or armor.stageIndex != last_armors[ai].get("si", 0):
                        armor_changed = true
                else:
                    armor_changed = true
            if armor_changed or armors_data.size() != last_armors.size():
                char_data["ar"] = armors_data
                has_change = true
        if is_instance_valid(character.componentManager):
            var bowling_comp = character.componentManager.GetComponentFromType("BowlingComponent")
            if is_instance_valid(bowling_comp) and bowling_comp.isRoll:
                char_data["px"] = snappedf(character.global_position.x, 1.0)
                char_data["py"] = snappedf(character.global_position.y, 1.0)
                has_change = true
        if is_instance_valid(character.buff):
            var buffs_data: Array = []
            for buffKey in character.buff.buffDictionary.keys():
                var buff: TowerDefenseCharacterBuffConfig = character.buff.buffDictionary[buffKey]
                var b_data: Dictionary = {"k": buffKey}
                if buff.get("time") != null:
                    b_data["t"] = snappedf(buff.get("time"), 0.01)
                if buff.get("currentTime") != null:
                    b_data["ct"] = snappedf(buff.get("currentTime"), 0.01)
                buffs_data.append(b_data)
            var last_char_bf: Array = last.get("bf", [])
            if buffs_data.size() > 0 or last_char_bf.size() > 0:
                char_data["bf"] = buffs_data
                has_change = true
        _character_last_sync_state[sync_id_val] = {
            "clip": cur_clip, "loop": cur_loop, "blendTime": cur_blend, "frame": cur_frame, 
            "dpi": char_data.get("dpi", 0), "hp": char_data.get("hp", character.instance.hitpoints if is_instance_valid(character.instance) else 0.0), 
            "ar": char_data.get("ar", []), 
            "bf": char_data.get("bf", [])
        }
        if has_change:
            characters_data.append(char_data)
    if characters_data.size() > 0:
        MultiPlayerManager.SendCharacterStateSync(JSON.stringify(characters_data))
    for key in invalid_keys:
        _sync_characters.erase(key)
        _character_last_sync_state.erase(key)

func _multiplayer_broadcast_plant_full_sync() -> void :
    if !Global.isMultiplayerMode or !MultiPlayerManager.isHost:
        return
    var plants_data: Array = []
    for plant in TowerDefenseManager.GetPlant():
        if !is_instance_valid(plant) or plant.isDestroy:
            continue
        var p_data: Dictionary = {
            "gx": plant.gridPos.x, 
            "gy": plant.gridPos.y, 
            "n": plant.packet.saveKey if is_instance_valid(plant.packet) else "", 
            "si": plant.sync_id
        }
        plants_data.append(p_data)
    for gravestone in get_tree().get_nodes_in_group("Gravestone"):
        if !is_instance_valid(gravestone) or gravestone.isDestroy:
            continue
        if gravestone is TowerDefenseGravestone:
            var g_data: Dictionary = {
                "gx": gravestone.gridPos.x, 
                "gy": gravestone.gridPos.y, 
                "n": gravestone.packet.saveKey if is_instance_valid(gravestone.packet) else "", 
                "si": gravestone.sync_id, 
                "gt": true
            }
            plants_data.append(g_data)
    MultiPlayerManager.SendPlantFullSync(JSON.stringify(plants_data))

func _multiplayer_apply_plant_full_sync(plants_data: Variant) -> void :
    if !(plants_data is Array):
        return
    if MultiPlayerManager.isHost:
        return
    var host_plants: Dictionary = {}
    for p_data in plants_data:
        if !(p_data is Dictionary):
            continue
        var gx: int = p_data.get("gx", 0)
        var gy: int = p_data.get("gy", 0)
        var p_name: String = p_data.get("n", "")
        var p_sync_id: int = p_data.get("si", -1)
        var is_gravestone: bool = p_data.get("gt", false)
        var grid_key: String = str(gx) + "_" + str(gy) + ("_g" if is_gravestone else "")
        host_plants[grid_key] = {"gx": gx, "gy": gy, "n": p_name, "si": p_sync_id, "gt": is_gravestone}
    var client_plants: Dictionary = {}
    for plant in TowerDefenseManager.GetPlant():
        if !is_instance_valid(plant) or plant.isDestroy:
            continue
        var grid_key: String = str(plant.gridPos.x) + "_" + str(plant.gridPos.y)
        client_plants[grid_key] = plant
    for gravestone in get_tree().get_nodes_in_group("Gravestone"):
        if !is_instance_valid(gravestone) or gravestone.isDestroy:
            continue
        if gravestone is TowerDefenseGravestone:
            var grid_key: String = str(gravestone.gridPos.x) + "_" + str(gravestone.gridPos.y) + "_g"
            client_plants[grid_key] = gravestone
    for grid_key in host_plants:
        if !client_plants.has(grid_key):
            var hp: Dictionary = host_plants[grid_key]
            if hp["n"] != "":
                _multiplayer_plant_at(hp["n"], Vector2i(hp["gx"], hp["gy"]), hp["si"])
    for grid_key in client_plants:
        if !host_plants.has(grid_key):
            var plant: TowerDefenseCharacter = client_plants[grid_key]
            if is_instance_valid(plant) and !plant.isDestroy:
                _cleanup_character_cell(plant)
                if is_instance_valid(plant.destroyComponent):
                    plant.destroyComponent.is_remote_destroy = true
                plant.Destroy()

var _last_cursor_pos: Vector2 = Vector2.ZERO
var _cursor_sync_counter: int = 0

func _send_cursor_sync() -> void :
    var mouse_pos: Vector2 = get_viewport().get_mouse_position()
    var pick_type: String = ""
    var pick_name: String = ""
    var packet_pick_ctrl = TowerDefenseManager.GetPacketPickControl()
    if is_instance_valid(packet_pick_ctrl):
        if is_instance_valid(packet_pick_ctrl.packetPick) and packet_pick_ctrl.packetPick.select:
            pick_type = "plant"
            pick_name = packet_pick_ctrl.packetPick.config.characterConfig.name
        elif packet_pick_ctrl.tools.size() > 0:
            for tool in packet_pick_ctrl.tools:
                if tool is ShovelPickTool and tool.IsPicking():
                    pick_type = "shovel"
                    var shovelName: String = GameSaveManager.GetKeyValue("CurrentShovel")
                    pick_name = shovelName if shovelName != "" else "ShovelDefault"
                    break
                elif tool is GlovePickTool and tool.IsPicking():
                    pick_type = "glove"
                    pick_name = "Glove"
                    break
    var pick_changed: bool = pick_type != _last_pick_type or pick_name != _last_pick_name
    _cursor_sync_counter += 1
    var cursor_moved: bool = mouse_pos.distance_to(_last_cursor_pos) > 5.0
    if cursor_moved or pick_changed or _cursor_sync_counter >= 10:
        MultiPlayerManager.SendCursorSync(mouse_pos.x, mouse_pos.y)
        _last_cursor_pos = mouse_pos
        _cursor_sync_counter = 0
    if pick_changed:
        _last_pick_type = pick_type
        _last_pick_name = pick_name
        MultiPlayerManager.SendCursorPickSync(pick_type, pick_name)

func _get_or_create_remote_cursor(user_id: String) -> RemoteCursor:
    if _remote_cursors.has(user_id):
        var existing: RemoteCursor = _remote_cursors[user_id]
        if is_instance_valid(existing):
            return existing
        _remote_cursors.erase(user_id)
    var gui_top: CanvasLayer = get_node_or_null("GUITop")
    if !is_instance_valid(gui_top):
        return null
    var cursor: RemoteCursor = load("res://Scene/TowerDefesne/TowerDefenseNew/RemoteCursor.tscn").instantiate()
    gui_top.add_child(cursor)
    var player_index: int = MultiPlayerManager.matchMembers.find(user_id)
    if player_index < 0:
        player_index = _remote_cursors.size()
    var player_name: String = MultiPlayerManager.GetPeerName(user_id)
    cursor.SetPlayerInfo(player_index, player_name)
    _remote_cursors[user_id] = cursor
    return cursor

func _remove_remote_cursor(user_id: String) -> void :
    if !_remote_cursors.has(user_id):
        return
    var cursor: RemoteCursor = _remote_cursors[user_id]
    _remote_cursors.erase(user_id)
    if is_instance_valid(cursor):
        cursor.queue_free()

func _on_remote_cursor_sync(data: Dictionary) -> void :
    var user_id: String = data.get("user_id", "")
    if user_id == "" or user_id == MultiPlayerManager.peerId:
        return
    var cursor: RemoteCursor = _get_or_create_remote_cursor(user_id)
    if !is_instance_valid(cursor):
        return
    var pos_x: float = data.get("x", -100.0)
    var pos_y: float = data.get("y", -100.0)
    cursor.UpdatePosition(pos_x, pos_y)

func _on_remote_cursor_pick_sync(data: Dictionary) -> void :
    var user_id: String = data.get("user_id", "")
    if user_id == "" or user_id == MultiPlayerManager.peerId:
        return
    var cursor: RemoteCursor = _get_or_create_remote_cursor(user_id)
    if !is_instance_valid(cursor):
        return
    var pick_type: String = data.get("pickType", "")
    var pick_name: String = data.get("pickName", "")
    cursor.UpdatePick(pick_type, pick_name)

func _on_choose_ready(data: Dictionary) -> void :
    var user_id: String = data.get("user_id", "")
    if user_id == "":
        return
    if _choose_ready_peers.has(user_id):
        return
    _choose_ready_peers.append(user_id)
    _update_choose_wait_label()
    if MultiPlayerManager.isHost:
        if _choose_ready_peers.has(MultiPlayerManager.peerId):
            var all_ready: bool = true
            for member_id: String in MultiPlayerManager.matchMembers:
                if !_choose_ready_peers.has(member_id):
                    all_ready = false
                    break
            if all_ready:
                MultiPlayerManager.SendChooseOver()
                _do_choose_over()
        else:
            if _choose_ready_peers.size() >= MultiPlayerManager.matchMembers.size():
                MultiPlayerManager.SendChooseOver()
                _do_choose_over()

func _on_choose_over() -> void :
    if !_choose_ready_peers.has(MultiPlayerManager.peerId):
        _choose_ready_peers.append(MultiPlayerManager.peerId)
    _do_choose_over()

func _do_choose_over() -> void :
    _choose_over_received = true
    _all_choose_ready.emit()

func _show_choose_wait_label() -> void :
    var gui_top: CanvasLayer = get_node_or_null("GUITop")
    if !is_instance_valid(gui_top):
        return
    _choose_wait_label = RichTextLabel.new()
    _choose_wait_label.bbcode_enabled = true
    _choose_wait_label.fit_content = true
    _choose_wait_label.z_index = 3000
    _choose_wait_label.z_as_relative = false
    _choose_wait_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _choose_wait_label.add_theme_font_size_override("normal_font_size", 22)
    _choose_wait_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2.0 - 150.0, 80.0)
    _choose_wait_label.size = Vector2(300.0, 200.0)
    gui_top.add_child(_choose_wait_label)
    _update_choose_wait_label()

func _hide_choose_wait_label() -> void :
    if is_instance_valid(_choose_wait_label):
        _choose_wait_label.queue_free()
    _choose_wait_label = null

func _update_choose_wait_label() -> void :
    if !is_instance_valid(_choose_wait_label):
        return
    var bbcode: String = "[center]"
    var waiting: bool = false
    for i: int in range(MultiPlayerManager.matchMembers.size()):
        var member_id: String = MultiPlayerManager.matchMembers[i]
        if !_choose_ready_peers.has(member_id):
            var color: Color = PLAYER_COLORS[i % PLAYER_COLORS.size()]
            var color_hex: String = color.to_html(false)
            var member_name: String = MultiPlayerManager.GetPeerName(member_id)
            bbcode += "[color=#%s]等待%s选卡[/color]\n" % [color_hex, member_name]
            waiting = true
    if !waiting:
        bbcode += "所有玩家已就绪"
    bbcode += "[/center]"
    _choose_wait_label.text = bbcode

func _on_multiplayer_state_received(op_code: String, data: String, sender_id: String) -> void :
    if op_code == MatchOpCodes.CURSOR_SYNC:
        var parsed = JSON.parse_string(data)
        if parsed:
            _on_remote_cursor_sync(parsed)
        return
    if op_code == MatchOpCodes.CURSOR_PICK_SYNC:
        var parsed = JSON.parse_string(data)
        if parsed:
            _on_remote_cursor_pick_sync(parsed)
        return
    if op_code == MatchOpCodes.CHOOSE_READY:
        var parsed = JSON.parse_string(data)
        if parsed:
            _on_choose_ready(parsed)
        return
    if op_code == MatchOpCodes.CHOOSE_OVER:
        _on_choose_over()
        return
    if op_code == MatchOpCodes.PAUSE:
        _multiplayer_apply_pause()
        return
    if op_code == MatchOpCodes.RESUME:
        _multiplayer_apply_resume()
        return
    if op_code == MatchOpCodes.CLIENT_READY:
        var parsed = JSON.parse_string(data)
        if parsed and parsed.has("user_id"):
            var user_id: String = parsed["user_id"]
            if !MultiPlayerManager._clients_ready.has(user_id):
                MultiPlayerManager._clients_ready.append(user_id)
            if MultiPlayerManager.CheckAllClientsReady():
                MultiPlayerManager.all_clients_ready.emit()
        return
    if op_code == MatchOpCodes.GAME_ENTRY:
        var parsed = JSON.parse_string(data)
        var round_num: int = parsed.get("round_num", 0) if parsed else 0
        if is_instance_valid(process) and process.isSurvival and is_instance_valid(process.survivalRunner):
            process.survivalRunner.roundNum = round_num
        GameEntry()
        MultiPlayerManager.SendGameEntryAck()
        return
    if op_code == MatchOpCodes.GAME_ENTRY_ACK:
        var parsed = JSON.parse_string(data)
        if parsed and parsed.has("user_id"):
            var user_id: String = parsed["user_id"]
            if !MultiPlayerManager._game_entry_acked.has(user_id):
                MultiPlayerManager._game_entry_acked.append(user_id)
            if MultiPlayerManager.CheckAllGameEntryAcked():
                MultiPlayerManager.all_game_entry_acked.emit()
        return
    if op_code == MatchOpCodes.TIPS_PLAY:
        var parsed = JSON.parse_string(data)
        if parsed:
            var tips_text: String = parsed.get("text", "")
            var tips_duration: float = parsed.get("duration", 2.0)
            if tips_text != "":
                levelControl.TipsPlay(tips_text, tips_duration)
        return
    if op_code == MatchOpCodes.DAMAGE_PART:
        var parsed = JSON.parse_string(data)
        if parsed:
            var dp_sync_id: int = parsed.get("sync_id", -1)
            var dp_part_name: String = parsed.get("part_name", "")


            var dp_vx: float = parsed.get("vx", 0.0)
            var dp_vy: float = parsed.get("vy", 0.0)
            if dp_sync_id >= 0 and _sync_characters.has(dp_sync_id) and dp_part_name != "":
                var character = _sync_characters[dp_sync_id]
                if is_instance_valid(character) and !character.isDestroy:
                    character.DamagePartCreate(StringName(dp_part_name), null, Vector2(dp_vx, dp_vy), true, Vector2.ZERO, true)
        return
    if op_code == MatchOpCodes.DAMAGE_POINT_REACH:
        var parsed = JSON.parse_string(data)
        if parsed:
            var dpr_sync_id: int = parsed.get("sync_id", -1)
            var dpr_name: String = parsed.get("damage_point_name", "")
            if dpr_sync_id >= 0 and _sync_characters.has(dpr_sync_id) and dpr_name != "":
                var character = _sync_characters[dpr_sync_id]
                if is_instance_valid(character) and !character.isDestroy:
                    character.DamagePointReach(dpr_name)
        return
    if op_code == MatchOpCodes.ARMOR_DAMAGE_POINT_REACH:
        var parsed = JSON.parse_string(data)
        if parsed:
            var adpr_sync_id: int = parsed.get("sync_id", -1)
            var adpr_name: String = parsed.get("armor_name", "")
            var adpr_stage: int = parsed.get("stage", 0)
            if adpr_sync_id >= 0 and _sync_characters.has(adpr_sync_id) and adpr_name != "":
                var character = _sync_characters[adpr_sync_id]
                if is_instance_valid(character) and !character.isDestroy:
                    character.ArmorDamagePointReach(adpr_name, adpr_stage)
        return
    if op_code == MatchOpCodes.ARMOR_HITPOINTS_EMPTY:
        var parsed = JSON.parse_string(data)
        if parsed:
            var ahe_sync_id: int = parsed.get("sync_id", -1)
            var ahe_name: String = parsed.get("armor_name", "")
            if ahe_sync_id >= 0 and _sync_characters.has(ahe_sync_id) and ahe_name != "":
                var character = _sync_characters[ahe_sync_id]
                if is_instance_valid(character) and !character.isDestroy:
                    character.ArmorHitpointsEmpty(ahe_name)
        return
    if op_code == MatchOpCodes.CRATER_CREATE:
        var parsed = JSON.parse_string(data)
        if parsed:
            var cc_grid_x: int = parsed.get("grid_x", 0)
            var cc_grid_y: int = parsed.get("grid_y", 0)
            var cc_name: String = parsed.get("crater_name", "CraterDayGround")
            var cc_cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(Vector2i(cc_grid_x, cc_grid_y))
            if is_instance_valid(cc_cell) and cc_cell.CanCraterCreate():
                var cc_packet: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(cc_name)
                if is_instance_valid(cc_packet):
                    cc_packet.Plant(Vector2i(cc_grid_x, cc_grid_y), false, true)
        return
    if op_code == MatchOpCodes.PLANT_FULL_SYNC:
        var parsed = JSON.parse_string(data)
        if parsed:
            _multiplayer_apply_plant_full_sync(parsed)
        return
    if op_code == MatchOpCodes.EVENT_EXECUTE:
        var parsed = JSON.parse_string(data)
        if parsed:
            var phase: String = parsed.get("phase", "")
            var events_raw = parsed.get("events", "")
            var events_parsed = JSON.parse_string(events_raw)
            if phase != "" and events_parsed is Array:
                var event_feature: TowerDefenseBattleFeatureEvent = GetFeature("Event")
                if is_instance_valid(event_feature):
                    event_feature.ApplyRemoteEventExecute(phase, events_parsed)
        return
    if op_code == MatchOpCodes.WAVE_EVENT_EXECUTE:
        var parsed = JSON.parse_string(data)
        if parsed:
            var events_raw = parsed.get("events", "")
            var events_parsed = JSON.parse_string(events_raw)
            if events_parsed is Array:
                for event_data in events_parsed:
                    if !(event_data is Dictionary):
                        continue
                    var event_name: String = event_data.get("EventName", "")
                    if event_name == "":
                        continue
                    var event = TowerDefenseLevelEventMathine.EventGet(event_name)
                    if !is_instance_valid(event):
                        continue
                    var event_value: Dictionary = event_data.get("Value", {})
                    event.Init(event_value)
                    event.Execute()
        return
    if MultiPlayerManager.isHost:
        _multiplayer_handle_client_action(op_code, data, sender_id)
    else:
        _multiplayer_handle_host_sync(op_code, data)

@warning_ignore("unused_parameter")
func _multiplayer_handle_client_action(op_code: String, data: String, sender_id: String) -> void :
    if sender_id == MultiPlayerManager.peerId:
        return
    var parsed = JSON.parse_string(data)
    if !parsed:
        return
    match op_code:
        MatchOpCodes.PLACE_PLANT:
            var plant_name: String = parsed.get("plant_name", "")
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            var override_data: String = parsed.get("override_data", "")
            var sync_id: int = _get_next_sync_id()
            if plant_name != "":
                var character = _multiplayer_plant_at(plant_name, Vector2i(grid_x, grid_y), sync_id, override_data)
                if is_instance_valid(character):
                    MultiPlayerManager.SendPlacePlant(plant_name, grid_x, grid_y, sync_id, override_data)
        MatchOpCodes.REMOVE_PLANT:
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            _multiplayer_remove_plant_at(Vector2i(grid_x, grid_y))
        MatchOpCodes.USE_SHOVEL:
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            _multiplayer_shovel_plant_at(Vector2i(grid_x, grid_y))
        MatchOpCodes.VASE_BREAK_REQUEST:
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            _multiplayer_vase_break_request(Vector2i(grid_x, grid_y))
        MatchOpCodes.PACKET_SPAWN:
            _multiplayer_apply_packet_spawn(parsed)
        MatchOpCodes.PACKET_PICK:
            var sync_id: int = parsed.get("sync_id", -1)
            var pick_type: String = parsed.get("pick_type", "remove")
            _multiplayer_apply_packet_pick(sync_id, pick_type)
        MatchOpCodes.SPAWN_SUN:
            _multiplayer_apply_spawn_sun(parsed)
        MatchOpCodes.SPAWN_COIN:
            _multiplayer_apply_spawn_coin(parsed)
        MatchOpCodes.SPAWN_FALLING_OBJECT:
            _multiplayer_apply_spawn_falling_object(parsed)

func _multiplayer_handle_host_sync(op_code: String, data: String) -> void :
    var parsed = JSON.parse_string(data)
    if !parsed:
        return
    if op_code == MatchOpCodes.CHARACTER_STATE_SYNC:
        _multiplayer_apply_character_state(parsed)
        return
    if op_code == MatchOpCodes.ZOMBIE_FULL_SYNC:
        _multiplayer_apply_zombie_state(parsed)
        return
    var sender_id: String = parsed.get("user_id", "")
    if sender_id == MultiPlayerManager.peerId:
        return
    match op_code:
        MatchOpCodes.PLACE_PLANT:
            var plant_name: String = parsed.get("plant_name", "")
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            var sync_id: int = parsed.get("sync_id", -1)
            var override_data: String = parsed.get("override_data", "")
            if plant_name != "":
                _multiplayer_plant_at(plant_name, Vector2i(grid_x, grid_y), sync_id, override_data)
        MatchOpCodes.REMOVE_PLANT:
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            _multiplayer_remove_plant_at(Vector2i(grid_x, grid_y))
        MatchOpCodes.USE_SHOVEL:
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            _multiplayer_shovel_plant_at(Vector2i(grid_x, grid_y))
        MatchOpCodes.SPAWN_ZOMBIE:
            var zombie_name: String = parsed.get("zombie_name", "")
            var line: int = parsed.get("line", 1)
            var offset_x: float = parsed.get("offset_x", 0.0)
            var sync_id: int = parsed.get("sync_id", -1)
            var spawn_override_str: String = parsed.get("spawn_override", "")
            var spawn_config_override_str: String = parsed.get("spawn_config_override", "")
            if zombie_name != "":
                _multiplayer_spawn_zombie(zombie_name, line, offset_x, sync_id, spawn_override_str, spawn_config_override_str)
        MatchOpCodes.SPAWN_GRID:
            var packet_name: String = parsed.get("packet_name", "")
            var grid_x: int = parsed.get("grid_x", 0)
            var grid_y: int = parsed.get("grid_y", 0)
            var sync_id: int = parsed.get("sync_id", -1)
            if packet_name != "":
                _multiplayer_plant_at(packet_name, Vector2i(grid_x, grid_y), sync_id)
        MatchOpCodes.SPAWN_CHARACTER_AT:
            _multiplayer_apply_spawn_character_at(parsed)
        MatchOpCodes.CONVEYOR_SPAWN:
            _multiplayer_apply_conveyor_spawn(parsed)
        MatchOpCodes.CHARACTER_DESTROY:
            var sync_id: int = parsed.get("sync_id", -1)
            var is_explode: bool = parsed.get("is_explode", false)
            var is_smash: bool = parsed.get("is_smash", false)
            if sync_id >= 0:
                if _sync_characters.has(sync_id):
                    var character = _sync_characters[sync_id]
                    if is_instance_valid(character) and !character.isDestroy:
                        character.destroy.disconnect(_on_sync_character_destroy)
                        _sync_characters.erase(sync_id)
                        _cleanup_character_cell(character)
                        if is_explode and is_instance_valid(character.instance) and character.instance.ashScene and !character.inWater:
                            var effect = TowerDefenseManager.CreateEffectSpriteOnce(character.instance.ashScene, character.gridPos, "Idle")
                            var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                            effect.global_position = character.sprite.global_position
                            effect.scale = character.scale * character.transformPoint.scale
                            charaterNode.add_child(effect)
                            effect.z_index -= 6
                        character.isExplode = is_explode
                        character.isSmash = is_smash
                        if is_instance_valid(character.destroyComponent):
                            character.destroyComponent.is_remote_destroy = true
                        character.Destroy()
                else:
                    _pending_destroy_sync_ids[sync_id] = {"is_explode": is_explode, "is_smash": is_smash}
        MatchOpCodes.CHARACTER_INIT:
            var sync_id: int = parsed.get("sync_id", -1)
            if sync_id >= 0 and _sync_characters.has(sync_id):
                var character = _sync_characters[sync_id]
                if is_instance_valid(character) and !character.isDestroy:
                    var init_x: float = parsed.get("x", character.global_position.x)
                    var init_y: float = parsed.get("y", character.global_position.y)
                    character.global_position = Vector2(init_x, init_y)
                    if parsed.has("hp") and is_instance_valid(character.instance):
                        character.instance.hitpoints = parsed["hp"]
                    if parsed.has("die") and parsed["die"]:
                        character.die = true
                    var init_clip: String = parsed.get("clip", "")
                    if init_clip != "":
                        var init_loop: bool = parsed.get("loop", true)
                        var init_blend: float = parsed.get("blendTime", 0.0)
                        character.SyncAnimation(init_clip, init_loop, init_blend)
                        if parsed.has("frame") and is_instance_valid(character.sprite):
                            character.sprite.frameIndex = parsed["frame"]
                    if parsed.has("timeScale"):
                        character.timeScale = parsed["timeScale"]
                    if parsed.has("walkSpeedScale") and character is TowerDefenseZombie:
                        character.walkSpeedScale = parsed["walkSpeedScale"]
                    if character is TowerDefensePlant:
                        character.state.process_mode = Node.PROCESS_MODE_INHERIT
        MatchOpCodes.CHARACTER_POSITION_SYNC:
            var sync_id: int = parsed.get("sync_id", -1)
            if sync_id >= 0 and _sync_characters.has(sync_id):
                var character = _sync_characters[sync_id]
                if is_instance_valid(character) and !character.isDestroy:
                    character.global_position = Vector2(parsed.get("x", character.global_position.x), parsed.get("y", character.global_position.y))
        MatchOpCodes.GAME_STATE_SYNC:
            _multiplayer_apply_state(parsed)
        MatchOpCodes.GAME_RESULT:
            if parsed.has("leave"):
                MultiPlayerManager.SendClientReady()
                SceneManager.ChangeScene("MainMenu")
                return
            var victory: bool = parsed.get("victory", false)
            if victory:
                levelControl.AwardCreate(levelControl.global_position)
            else:
                for character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
                    character.process_mode = Node.PROCESS_MODE_DISABLED
                isGameFail = true
                isGameRunning = false
                ZombieWonLevelFail(false)
        MatchOpCodes.VASE_BREAK:
            _multiplayer_apply_vase_break(parsed)
        MatchOpCodes.PACKET_SPAWN:
            _multiplayer_apply_packet_spawn(parsed)
        MatchOpCodes.PACKET_PICK:
            var sync_id: int = parsed.get("sync_id", -1)
            var pick_type: String = parsed.get("pick_type", "remove")
            _multiplayer_apply_packet_pick(sync_id, pick_type)

func _multiplayer_apply_character_state(characters_data: Variant) -> void :
    if characters_data is Array:
        for char_data in characters_data:
            if !(char_data is Dictionary):
                continue
            var sync_id_val: int = char_data.get("sync_id", -1)
            if sync_id_val < 0 or !_sync_characters.has(sync_id_val):
                continue
            var character = _sync_characters[sync_id_val]
            if !is_instance_valid(character) or character.isDestroy:
                continue
            var clip_name: String = char_data.get("clip", "")
            if clip_name != "" and is_instance_valid(character.sprite):
                if character.sprite.clip != clip_name:
                    var loop_anim: bool = char_data.get("loop", true)
                    var blend_time: float = char_data.get("blendTime", 0.0)
                    character.SyncAnimation(clip_name, loop_anim, blend_time)
                if char_data.has("frame"):
                    var sync_frame: int = char_data["frame"]
                    if character.sprite.frameIndex != sync_frame:
                        character.sprite.frameIndex = sync_frame
            if char_data.has("px") and char_data.has("py"):
                character.global_position = Vector2(char_data["px"], char_data["py"])
            if char_data.has("hp") and is_instance_valid(character.instance):
                var sync_hp: float = char_data["hp"]
                character.instance.hitpoints = sync_hp
                if sync_hp <= character.instance.hitpointsNearDeath and !character.instance.nearDie:
                    character.instance.nearDie = true
                    character.nearDie = true
            if char_data.has("components") and is_instance_valid(character.componentManager):
                var components_data: Dictionary = char_data["components"]
                for component_name in components_data.keys():
                    var component = character.componentManager.GetComponentFromType(component_name)
                    if is_instance_valid(component) and component.has_method("SyncDeserialize"):
                        component.SyncDeserialize(components_data[component_name])
            if char_data.has("dpi") and is_instance_valid(character.instance) and character.instance.damagePointData:
                var sync_dpi: int = char_data["dpi"]
                if sync_dpi > character.instance.damagePointIndex:
                    for di in range(character.instance.damagePointIndex, sync_dpi):
                        if di < character.instance.damagePoints.size():
                            var dp_name: String = character.instance.damagePoints[di]["Name"]
                            character.instance.damagePointData.SetDamagePointFliters(character.sprite, dp_name)
                            if character.config.customData:
                                for customName: String in character.currentCustom:
                                    character.config.customData.SetDamagePoint(character.sprite, customName, di)
                            character.DamagePointReach(dp_name)
                    character.instance.damagePointIndex = sync_dpi
            if char_data.has("ar") and is_instance_valid(character.instance):
                var armors_data: Array = char_data["ar"]
                var armor_remove_list: Array[TowerDefenseArmorInstance] = []
                for a_data in armors_data:
                    var armor_idx: int = a_data.get("i", -1)
                    if armor_idx < 0 or armor_idx >= character.instance.armorList.size():
                        continue
                    var armor: TowerDefenseArmorInstance = character.instance.armorList[armor_idx]
                    if !is_instance_valid(armor):
                        continue
                    if a_data.get("rm", false):
                        if !armor.isRemove:
                            armor.Remove()
                            armor.isRemove = true
                        armor_remove_list.append(armor)
                        continue
                    if armor.isRemove:
                        continue
                    if a_data.has("hp"):
                        armor.hitPoints = a_data["hp"]
                    if a_data.has("si"):
                        var sync_si: int = a_data["si"]
                        if sync_si > armor.stageIndex:
                            for s in range(armor.stageIndex, sync_si):
                                armor.SetDamageStage(s + 1)
                            armor.stageIndex = sync_si
                    if armor.hitPoints <= 0 and !armor.isRemove:
                        if armor.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DROPABLE:
                            character.DamagePartCreate(StringName(armor.config.armorName), null, Vector2(randf_range(-100, 100), -300), true, Vector2.ZERO, true)
                        armor.Remove()
                        armor.isRemove = true
                        armor_remove_list.append(armor)
                for armor_instance: TowerDefenseArmorInstance in armor_remove_list:
                    character.instance.armorList.erase(armor_instance)
                    character.instance.armorShield.erase(armor_instance)
                    character.instance.armorHelm.erase(armor_instance)
                    character.instance.armorBody.erase(armor_instance)
                    character.instance.armorHeadCover.erase(armor_instance)
            if char_data.has("bf") and is_instance_valid(character.buff):
                character.buff.is_syncing = true
                var buffs_data: Array = char_data["bf"]
                var synced_keys: Dictionary = {}
                for b_data in buffs_data:
                    var buff_key: String = b_data.get("k", "")
                    if buff_key == "":
                        continue
                    synced_keys[buff_key] = true
                    if !character.buff.BuffHas(buff_key):
                        var new_buff: TowerDefenseCharacterBuffConfig = TowerDefenseCharacterBuffConfig.CreateBuffByKey(buff_key)
                        if is_instance_valid(new_buff):
                            new_buff.character = character
                            character.buff.buffDictionary[buff_key] = new_buff
                            new_buff.Enter()
                            if b_data.has("t"):
                                new_buff.set("time", b_data["t"])
                            if b_data.has("ct"):
                                new_buff.set("currentTime", b_data["ct"])
                    else:
                        var existing_buff: TowerDefenseCharacterBuffConfig = character.buff.buffDictionary[buff_key]
                        if is_instance_valid(existing_buff):
                            if b_data.has("t"):
                                existing_buff.set("time", b_data["t"])
                            if b_data.has("ct"):
                                existing_buff.set("currentTime", b_data["ct"])
                var keys_to_remove: Array = []
                for existing_key in character.buff.buffDictionary.keys():
                    if !synced_keys.has(existing_key):
                        keys_to_remove.append(existing_key)
                for key in keys_to_remove:
                    var remove_buff: TowerDefenseCharacterBuffConfig = character.buff.buffDictionary[key]
                    if is_instance_valid(remove_buff):
                        remove_buff.Exit()
                    character.buff.buffDictionary.erase(key)
                character.buff.is_syncing = false

func _multiplayer_apply_state(_state: Dictionary) -> void :
    for featureName in _state.keys():
        if featureName == "process":
            if process:
                process.SyncDeserialize(_state["process"])
        elif featureDictionary.has(featureName):
            featureDictionary[featureName].SyncDeserialize(_state[featureName])
        else:
            AddFeature(featureName, {})
            if featureDictionary.has(featureName):
                featureDictionary[featureName].SyncDeserialize(_state[featureName])

func _multiplayer_remove_plant_at(grid_pos: Vector2i) -> void :
    for plant in TowerDefenseManager.GetPlant():
        if !is_instance_valid(plant):
            continue
        if plant.gridPos == grid_pos:
            _cleanup_character_cell(plant)
            if is_instance_valid(plant.destroyComponent):
                plant.destroyComponent.is_remote_destroy = true
            plant.Destroy()
            return

func _multiplayer_shovel_plant_at(grid_pos: Vector2i) -> void :
    for plant in TowerDefenseManager.GetPlant():
        if !is_instance_valid(plant):
            continue
        if plant.gridPos == grid_pos:
            _cleanup_character_cell(plant)
            if is_instance_valid(plant.destroyComponent):
                plant.destroyComponent.is_remote_destroy = true
            plant.ShovelDestroy()
            return

func _multiplayer_plant_at(plant_name: String, grid_pos: Vector2i, sync_id: int = -1, override_str: String = "") -> TowerDefenseCharacter:
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(plant_name)
    if !is_instance_valid(packetConfig):
        return null
    var override_obj: TowerDefensePacketOverride = null
    var original_override: TowerDefensePacketOverride = packetConfig.override
    if override_str != "":
        var override_data = JSON.parse_string(override_str)
        if override_data is Dictionary:
            override_obj = TowerDefensePacketOverride.new()
            override_obj.Init(override_data)
            packetConfig.override = override_obj
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(grid_pos)
    if !is_instance_valid(cell):
        return null
    var no_limit: bool = false
    var has_cover: bool = !packetConfig.GetPlantCover().is_empty() or packetConfig.characterConfig.plantCoverSelf
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        if has_cover:
            var cover_target: TowerDefenseCharacter = _find_cover_target(cell, packetConfig)
            if is_instance_valid(cover_target):
                if cover_target.sync_id >= 0:
                    if _sync_characters.has(cover_target.sync_id):
                        _sync_characters.erase(cover_target.sync_id)
                    if cover_target.destroy.is_connected(_on_sync_character_destroy):
                        cover_target.destroy.disconnect(_on_sync_character_destroy)
                _cleanup_character_cell(cover_target)
                if is_instance_valid(cover_target.destroyComponent):
                    cover_target.destroyComponent.is_remote_destroy = true
                cover_target.Destroy()
        no_limit = true
    else:
        no_limit = !has_cover
        if !cell.CanPacketPlant(packetConfig, no_limit):
            if !has_cover:
                var existingPlant = cell.GetShovelCharacter(0.5)
                if is_instance_valid(existingPlant):
                    if Global.isMultiplayerMode and MultiPlayerManager.isHost and existingPlant.sync_id >= 0:
                        MultiPlayerManager.SendCharacterDestroy(existingPlant.sync_id)
                    _cleanup_character_cell(existingPlant)
                    if is_instance_valid(existingPlant.destroyComponent):
                        existingPlant.destroyComponent.is_remote_destroy = true
                    existingPlant.Destroy()
            else:
                var cover_target: TowerDefenseCharacter = _find_cover_target(cell, packetConfig)
                if is_instance_valid(cover_target):
                    if cover_target.sync_id >= 0:
                        if _sync_characters.has(cover_target.sync_id):
                            _sync_characters.erase(cover_target.sync_id)
                        if cover_target.destroy.is_connected(_on_sync_character_destroy):
                            cover_target.destroy.disconnect(_on_sync_character_destroy)
                    _cleanup_character_cell(cover_target)
                    if is_instance_valid(cover_target.destroyComponent):
                        cover_target.destroyComponent.is_remote_destroy = true
                    cover_target.Destroy()
                no_limit = true
    var character = packetConfig.Plant(grid_pos, true, no_limit)
    if is_instance_valid(override_obj):
        packetConfig.override = original_override
    if is_instance_valid(character) and sync_id >= 0:
        _register_sync_character(sync_id, character)
    return character

func _find_cover_target(cell: TowerDefenseCellInstance, packetConfig: TowerDefensePacketConfig) -> TowerDefenseCharacter:
    if !packetConfig.GetPlantCover().is_empty():
        for character: TowerDefenseCharacter in cell.characterList:
            if !is_instance_valid(character) or character.isDestroy:
                continue
            if packetConfig.GetPlantCover().has(character.config.name):
                return character
    if packetConfig.characterConfig.plantCoverSelf:
        for character: TowerDefenseCharacter in cell.characterList:
            if !is_instance_valid(character) or character.isDestroy:
                continue
            if character.config.name == packetConfig.characterConfig.name:
                return character
    return null

func _multiplayer_spawn_zombie(zombie_name: String, line: int, offset_x: float, sync_id: int = -1, spawn_override_str: String = "", spawn_config_override_str: String = "") -> void :
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombie_name)
    if !is_instance_valid(packetConfig):
        return
    var character = packetConfig.Spawn(line, offset_x)
    if !is_instance_valid(character):
        return
    if spawn_override_str != "":
        var override_data = JSON.parse_string(spawn_override_str)
        if override_data is Dictionary:
            var override_obj: TowerDefenseCharacterOverride = TowerDefenseCharacterOverride.new()
            if is_instance_valid(override_obj):
                override_obj.Init(override_data)
                override_obj.ExecuteCharacter(character)
    if spawn_config_override_str != "":
        var config_override_data = JSON.parse_string(spawn_config_override_str)
        if config_override_data is Dictionary:
            var config_override_obj: TowerDefenseCharacterOverride = TowerDefenseCharacterOverride.new()
            if is_instance_valid(config_override_obj):
                config_override_obj.Init(config_override_data)
                config_override_obj.ExecuteCharacter(character)
    if sync_id >= 0:
        _register_sync_character(sync_id, character)

func _multiplayer_apply_spawn_character_at(data: Dictionary) -> void :
    var packet_name: String = data.get("packet_name", "")
    var grid_x: int = data.get("grid_x", 0)
    var grid_y: int = data.get("grid_y", 0)
    var sync_id: int = data.get("sync_id", -1)
    var hitpoint_scale: float = data.get("hitpoint_scale", 1.0)
    var scale_val: float = data.get("scale", 1.0)
    var hypnoses: bool = data.get("hypnoses", false)
    var rise_duration: float = data.get("rise_duration", 0.0)
    var use_create: bool = data.get("use_create", false)
    var pos_x: float = data.get("pos_x", 0.0)
    var pos_y: float = data.get("pos_y", 0.0)
    var walk_after_spawn: bool = data.get("walk_after_spawn", false)
    var ground_height: float = data.get("ground_height", 0.0)
    var size_val: String = data.get("size", "")
    if packet_name == "":
        return
    var packet_config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packet_name)
    if !is_instance_valid(packet_config):
        return
    var grid_pos: Vector2i = Vector2i(grid_x, grid_y)
    var character: TowerDefenseCharacter
    if use_create:
        character = packet_config.Create(Vector2(pos_x, pos_y), grid_pos, ground_height)
        if is_instance_valid(character):
            TowerDefenseCharacter.characterNode.add_child.call_deferred(character)
            var _hp_scale: float = hitpoint_scale
            var _scale: float = scale_val
            var _hypnoses: bool = hypnoses
            var _rise: float = rise_duration
            var _walk: bool = walk_after_spawn
            var _size: String = size_val
            ( func():
                if is_instance_valid(character):
                    if _size != "" and character.has_method("SetSize"):
                        character.SetSize(_size)
                    if _hp_scale != 1.0 and is_instance_valid(character.instance):
                        character.instance.hitpointScale = _hp_scale
                    if _scale != 1.0 and is_instance_valid(character.transformPoint):
                        character.transformPoint.scale = Vector2(_scale, _scale)
                    if _hypnoses:
                        character.Hypnoses()
                    if _rise > 0.0:
                        character.Rise(_rise)
                    if _walk:
                        character.Walk()).call_deferred()
    else:
        character = packet_config.Plant(grid_pos, true, true)
        if is_instance_valid(character):
            if size_val != "" and character.has_method("SetSize"):
                character.SetSize.call_deferred(size_val)
            if hitpoint_scale != 1.0 and is_instance_valid(character.instance):
                character.instance.hitpointScale = hitpoint_scale
            if scale_val != 1.0 and is_instance_valid(character.transformPoint):
                character.transformPoint.scale = Vector2(scale_val, scale_val)
            if hypnoses:
                character.Hypnoses.call_deferred()
            if rise_duration > 0.0:
                character.Rise.call_deferred(rise_duration)
            if walk_after_spawn:
                character.Walk.call_deferred()
    if is_instance_valid(character) and sync_id >= 0:
        _register_sync_character(sync_id, character)

func _multiplayer_apply_conveyor_spawn(data: Dictionary) -> void :
    var packet_name: String = data.get("packet_name", "")
    var packet_type: String = data.get("packet_type", "Default")
    if packet_name == "":
        return
    var packet_config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packet_name)
    if !is_instance_valid(packet_config):
        return
    var conveyor_feature: TowerDefenseBattleFeatureConveyorBelt = GetFeature("ConveyorBelt")
    if !is_instance_valid(conveyor_feature):
        return
    conveyor_feature.SpawnPacketFromSync(packet_config, packet_type)

func _cleanup_pending_destroys() -> void :
    if _pending_destroy_sync_ids.is_empty():
        return
    var keys_to_remove: Array = []
    for key in _pending_destroy_sync_ids:
        if !_sync_characters.has(key):
            keys_to_remove.append(key)
    for key in keys_to_remove:
        _pending_destroy_sync_ids.erase(key)

func _register_sync_character(sync_id_val: int, character: TowerDefenseCharacter) -> void :
    if _sync_characters.has(sync_id_val):
        var old_character = _sync_characters[sync_id_val]
        if is_instance_valid(old_character) and old_character != character:
            if old_character.destroy.is_connected(_on_sync_character_destroy):
                old_character.destroy.disconnect(_on_sync_character_destroy)
            if !old_character.isDestroy:
                if is_instance_valid(old_character.destroyComponent):
                    old_character.destroyComponent.is_remote_destroy = true
                old_character.Destroy()
    character.sync_id = sync_id_val
    _sync_characters[sync_id_val] = character
    character.destroy.connect(_on_sync_character_destroy)
    if _pending_destroy_sync_ids.has(sync_id_val):
        var pending_data: Dictionary = _pending_destroy_sync_ids[sync_id_val]
        _pending_destroy_sync_ids.erase(sync_id_val)
        if is_instance_valid(character) and !character.isDestroy:
            character.destroy.disconnect(_on_sync_character_destroy)
            _sync_characters.erase(sync_id_val)
            _cleanup_character_cell(character)
            var pending_explode: bool = pending_data.get("is_explode", false)
            var pending_smash: bool = pending_data.get("is_smash", false)
            if pending_explode and is_instance_valid(character.instance) and character.instance.ashScene and !character.inWater:
                var effect = TowerDefenseManager.CreateEffectSpriteOnce(character.instance.ashScene, character.gridPos, "Idle")
                var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                effect.global_position = character.sprite.global_position
                effect.scale = character.scale * character.transformPoint.scale
                charaterNode.add_child(effect)
                effect.z_index -= 6
            character.isExplode = pending_explode
            character.isSmash = pending_smash
            if is_instance_valid(character.destroyComponent):
                character.destroyComponent.is_remote_destroy = true
            character.Destroy()
        return
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        _sync_character_init_timer.call_deferred(sync_id_val)
        _sync_character_position_timer.call_deferred(sync_id_val)

func _sync_character_init_timer(sync_id_val: int) -> void :
    await get_tree().process_frame
    await get_tree().process_frame
    if !_sync_characters.has(sync_id_val):
        return
    var character = _sync_characters[sync_id_val]
    if !is_instance_valid(character) or character.isDestroy:
        return
    if !is_instance_valid(character.sprite):
        await character.ready
    if !_sync_characters.has(sync_id_val):
        return
    character = _sync_characters[sync_id_val]
    if !is_instance_valid(character) or character.isDestroy:
        return
    var current_clip: String = ""
    var current_loop: bool = true
    var current_blend: float = 0.0
    var current_frame: int = 0
    if is_instance_valid(character.sprite):
        current_clip = character.sprite.clip
        current_loop = character.sprite.loop
        current_blend = character.sprite.blendTime
        current_frame = character.sprite.frameIndex
    MultiPlayerManager.SendCharacterInit(
        sync_id_val, 
        character.global_position.x, 
        character.global_position.y, 
        character.instance.hitpoints if is_instance_valid(character.instance) else 0.0, 
        character.die, 
        current_clip, 
        current_loop, 
        current_blend, 
        current_frame, 
        character.timeScale, 
        character.walkSpeedScale if character is TowerDefenseZombie else 1.0
    )

func _sync_character_position_timer(sync_id_val: int) -> void :
    await get_tree().create_timer(2.0, false).timeout
    if !_sync_characters.has(sync_id_val):
        return
    var character = _sync_characters[sync_id_val]
    if !is_instance_valid(character) or character.isDestroy:
        return
    MultiPlayerManager.SendCharacterPositionSync(
        sync_id_val, 
        character.global_position.x, 
        character.global_position.y
    )

func _on_sync_character_destroy(character: TowerDefenseCharacter) -> void :
    if character.sync_id >= 0:
        _sync_characters.erase(character.sync_id)
        _zombie_target_positions.erase(character.sync_id)
        _zombie_last_sync_state.erase(character.sync_id)
        _zombie_sync_velocities.erase(character.sync_id)
        _zombie_last_sync_time.erase(character.sync_id)
        _zombie_sync_miss_count.erase(character.sync_id)
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            MultiPlayerManager.SendCharacterDestroy(character.sync_id, character.isExplode, character.isSmash)

func _cleanup_character_cell(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character):
        return
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(character.gridPos)
    if is_instance_valid(cell) and cell.characterList.has(character):
        if character.destroy.is_connected(cell.CharacterDestroy):
            character.destroy.disconnect(cell.CharacterDestroy)
        cell.CharacterDestroy(character)
    if is_instance_valid(character.config) and character.config is TowerDefensePlantConfig:
        for offset in character.config.extendGrid:
            var extend_cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(character.gridPos + offset)
            if is_instance_valid(extend_cell) and extend_cell != cell and extend_cell.characterList.has(character):
                if character.destroy.is_connected(extend_cell.CharacterDestroy):
                    character.destroy.disconnect(extend_cell.CharacterDestroy)
                extend_cell.CharacterDestroy(character)

func _get_next_sync_id() -> int:
    _sync_id_counter += 1
    return _sync_id_counter

func _get_next_packet_sync_id() -> int:
    _packet_sync_id_counter += 1
    return _packet_sync_id_counter

func _register_sync_packet(sync_id: int, packet: TowerDefenseInGamePacketShow) -> void :
    _sync_packets[sync_id] = packet

func _unregister_sync_packet(sync_id: int) -> void :
    _sync_packets.erase(sync_id)

func _multiplayer_collect_sun_by_instance_id(sun_instance_id: int) -> void :
    for sun in get_tree().get_nodes_in_group("Sun"):
        if !is_instance_valid(sun):
            continue
        if sun.get_instance_id() == sun_instance_id:
            if sun.has_method("Collection"):
                sun.Collection()
            return

func _on_multiplayer_victory() -> void :
    if MultiPlayerManager.isHost:
        MultiPlayerManager.SendGameResult(true)

func _on_multiplayer_failed() -> void :
    if MultiPlayerManager.isHost:
        MultiPlayerManager.SendGameResult(false)

@warning_ignore("unused_parameter")
func _on_multiplayer_peer_left(_username: String, peer_id: String) -> void :
    _remove_remote_cursor(peer_id)

func _multiplayer_vase_break_request(grid_pos: Vector2i) -> void :
    if !MultiPlayerManager.isHost:
        return
    for vase in get_tree().get_nodes_in_group("Vase"):
        if !is_instance_valid(vase) or vase.over:
            continue
        if vase.gridPos == grid_pos:
            vase.Destroy()
            return

func _multiplayer_apply_vase_break(data: Dictionary) -> void :
    var grid_x: int = data.get("grid_x", 0)
    var grid_y: int = data.get("grid_y", 0)
    var grid_pos: Vector2i = Vector2i(grid_x, grid_y)
    var content_type: String = data.get("content_type", "none")
    var content_name: String = data.get("content_name", "")
    var ground_height: float = data.get("ground_height", 0.0)
    var hypnoses: bool = data.get("hypnoses", false)

    var target_vase: TowerDefenseVase = null
    for vase in get_tree().get_nodes_in_group("Vase"):
        if !is_instance_valid(vase) or vase.over:
            continue
        if vase.gridPos == grid_pos:
            target_vase = vase
            break
    if is_instance_valid(target_vase):
        target_vase.MultiplayerBreak()

    if content_type == "zombie" and content_name != "":
        var packet_config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(content_name)
        if is_instance_valid(packet_config):
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(grid_pos)
            if is_instance_valid(cell) and cell.CanPacketPlant(packet_config):
                var zombie = packet_config.Plant(grid_pos, true)
                if is_instance_valid(zombie):
                    zombie.instance.wakeUp = true
                    zombie.groundHeight = ground_height
                    if hypnoses:
                        zombie.Hypnoses()
                    var sync_id: int = data.get("sync_id", -1)
                    if sync_id >= 0:
                        _register_sync_character(sync_id, zombie)
    elif content_type == "plant" and data.has("packet_show"):
        var ps_data: Dictionary = data["packet_show"]
        var packet_name: String = ps_data.get("packet_name", "")
        if packet_name != "":
            var packet_config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packet_name)
            if is_instance_valid(packet_config):
                var packet_instance: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
                packet_instance.z_index = ps_data.get("z_index", 0)
                packet_instance.global_position = Vector2(ps_data.get("pos_x", 0.0), ps_data.get("pos_y", 0.0))
                TowerDefenseGroundItemBase.characterNode.add_child(packet_instance)
                packet_instance.Init(packet_config)
                packet_instance.onlyDraw = false
                packet_instance.showCost = false
                packet_instance.useCost = false
                packet_instance.plantOnce = true
                packet_instance.canPressPutBack = false
                packet_instance.StartInit()
                packet_instance.alive = true
                packet_instance.aliveTime = 15.0
                packet_instance.height = 0
                packet_instance.moveComponent.gravity = 980.0
                packet_instance.moveComponent.velocity = Vector2(ps_data.get("velocity_x", 0.0), ps_data.get("velocity_y", -300.0))
                var packet_pick_control: PacketPickControl = TowerDefenseManager.GetPacketPickControl()
                if is_instance_valid(packet_pick_control):
                    packet_instance.pressed.connect(packet_pick_control.PickPacket)
                packet_instance.add_to_group("VasePacketShow")
                var ps_sync_id: int = ps_data.get("sync_id", -1)
                if ps_sync_id >= 0:
                    packet_instance.set_meta("packet_sync_id", ps_sync_id)
                    _register_sync_packet(ps_sync_id, packet_instance)

func _multiplayer_apply_packet_spawn(data: Dictionary) -> void :
    var sync_id: int = data.get("sync_id", -1)
    var packet_name: String = data.get("packet_name", "")
    var pos_x: float = data.get("pos_x", 0.0)
    var pos_y: float = data.get("pos_y", 0.0)
    var alive_time: float = data.get("alive_time", 15.0)
    var is_fall: bool = data.get("is_fall", false)
    var use_cost: bool = data.get("use_cost", false)
    var velocity_x: float = data.get("velocity_x", 0.0)
    var velocity_y: float = data.get("velocity_y", -300.0)
    var z_index: int = data.get("z_index", 0)
    var fall_height: float = data.get("fall_height", 0.0)
    if packet_name == "" or sync_id < 0:
        return
    var packet_config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packet_name)
    if !is_instance_valid(packet_config):
        return
    var packet_instance: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    packet_instance.z_index = z_index
    packet_instance.global_position = Vector2(pos_x, pos_y)
    TowerDefenseGroundItemBase.characterNode.add_child(packet_instance)
    packet_instance.Init(packet_config)
    packet_instance.onlyDraw = false
    packet_instance.showCost = use_cost
    packet_instance.useCost = use_cost
    packet_instance.plantOnce = true
    packet_instance.canPressPutBack = false
    packet_instance.StartInit()
    packet_instance.alive = true
    packet_instance.aliveTime = alive_time
    if use_cost:
        packet_instance.start = true
    if is_fall:
        var tween = packet_instance.create_tween()
        tween.tween_property(packet_instance, ^"global_position:y", fall_height, (fall_height - pos_y) / 25.0)
    else:
        packet_instance.height = 1
        packet_instance.moveComponent.gravity = 980.0
        packet_instance.moveComponent.velocity = Vector2(velocity_x, velocity_y)
    var packet_pick_control: PacketPickControl = TowerDefenseManager.GetPacketPickControl()
    if is_instance_valid(packet_pick_control):
        packet_instance.pressed.connect(packet_pick_control.PickPacket)
    packet_instance.set_meta("packet_sync_id", sync_id)
    _register_sync_packet(sync_id, packet_instance)

func _multiplayer_apply_packet_pick(sync_id: int, pick_type: String = "remove") -> void :
    if sync_id < 0:
        return
    var packet_pick_control: PacketPickControl = TowerDefenseManager.GetPacketPickControl()
    var packet = _sync_packets.get(sync_id)
    if !is_instance_valid(packet):
        _sync_packets.erase(sync_id)
        return
    match pick_type:
        "lock":
            packet.alive = false
            packet.button.mouse_filter = Control.MOUSE_FILTER_IGNORE
        "unlock":
            packet.alive = true
            packet.button.mouse_filter = Control.MOUSE_FILTER_PASS
        _:
            if is_instance_valid(packet_pick_control) and is_instance_valid(packet_pick_control.packetPick) and packet_pick_control.packetPick == packet:
                packet_pick_control.PacketPickRelease()
            _sync_packets.erase(sync_id)
            packet.queue_free()

func _multiplayer_apply_pause() -> void :
    if _is_multiplayer_paused:
        return
    _is_multiplayer_paused = true
    AudioManager.AudioPlay("Pause", AudioManagerEnum.TYPE.SFX, 0.0, true, true)
    DialogManager.DialogCreate("BattlePause")
    if is_instance_valid(buttonPause):
        buttonPause.button_pressed = true

func _multiplayer_apply_resume() -> void :
    if !_is_multiplayer_paused:
        return
    _is_multiplayer_paused = false
    var dialog_layer = DialogManager.dialogLayer
    if is_instance_valid(dialog_layer):
        for child in dialog_layer.get_children():
            if is_instance_valid(child) and child.get_script() and child.get_script().resource_path.find("DialogBattlePause") >= 0:
                child.Close()
                return
    if is_instance_valid(buttonPause):
        buttonPause.button_pressed = false

func _multiplayer_apply_spawn_sun(data: Dictionary) -> void :
    var sun_type: String = data.get("sun_type", "Normal")
    var pos_x: float = data.get("pos_x", 0.0)
    var pos_y: float = data.get("pos_y", 0.0)
    var sun_num: int = data.get("sun_num", 25)
    var velocity_x: float = data.get("velocity_x", 0.0)
    var velocity_y: float = data.get("velocity_y", -400.0)
    var gravity: float = data.get("gravity", 980.0)
    var height: float = data.get("height", 0.0)
    var move_stop_time: float = data.get("move_stop_time", -1.0)
    var moving_method: int = data.get("moving_method", 0)
    match sun_type:
        "Normal":
            TowerDefenseManager.SunCreate(Vector2(pos_x, pos_y), sun_num, moving_method as TowerDefenseEnum.SUN_MOVING_METHOD, height, Vector2(velocity_x, velocity_y), gravity, move_stop_time)
        "Brain":
            TowerDefenseManager.BrainSunCreate(Vector2(pos_x, pos_y), sun_num, moving_method as TowerDefenseEnum.SUN_MOVING_METHOD, height, Vector2(velocity_x, velocity_y), gravity, move_stop_time)
        "Jala":
            TowerDefenseManager.JalapenoSunCreate(Vector2(pos_x, pos_y), sun_num, moving_method as TowerDefenseEnum.SUN_MOVING_METHOD, height, Vector2(velocity_x, velocity_y), gravity, move_stop_time)

func _multiplayer_apply_spawn_coin(data: Dictionary) -> void :
    var pos_x: float = data.get("pos_x", 0.0)
    var pos_y: float = data.get("pos_y", 0.0)
    var num: int = data.get("num", 10)
    var velocity_x: float = data.get("velocity_x", 0.0)
    var velocity_y: float = data.get("velocity_y", -400.0)
    var gravity: float = data.get("gravity", 980.0)
    var height: float = data.get("height", 0.0)
    var collect: bool = data.get("collect", false)
    TowerDefenseManager.CoinCreate(Vector2(pos_x, pos_y), num, height, Vector2(velocity_x, velocity_y), gravity, collect)

func _multiplayer_apply_spawn_falling_object(data: Dictionary) -> void :
    var pos_x: float = data.get("pos_x", 0.0)
    var pos_y: float = data.get("pos_y", 0.0)
    var velocity_x: float = data.get("velocity_x", 0.0)
    var velocity_y: float = data.get("velocity_y", -400.0)
    var gravity: float = data.get("gravity", 980.0)
    var height: float = data.get("height", 0.0)
    TowerDefenseManager.FallingObjectCreate(Vector2(pos_x, pos_y), height, Vector2(velocity_x, velocity_y), gravity)

func _multiplayer_broadcast_zombie_state() -> void :
    var all_zombie_keys: Array = []
    var all_zombie_infos: Array = []
    var invalid_keys: Array = []
    for sync_id_val in _sync_characters.keys():
        var character = _sync_characters[sync_id_val]
        if !is_instance_valid(character):
            invalid_keys.append(sync_id_val)
            continue
        if character.isDestroy:
            continue
        if character is TowerDefenseZombie:
            all_zombie_keys.append(sync_id_val)
            var zombie_info: Dictionary = {"i": sync_id_val}
            if is_instance_valid(character.config):
                zombie_info["n"] = character.config.name
            zombie_info["x"] = snappedf(character.global_position.x, 1.0)
            zombie_info["y"] = snappedf(character.global_position.y, 1.0)
            zombie_info["g"] = character.gridPos.y
            all_zombie_infos.append(zombie_info)
    for key in invalid_keys:
        _sync_characters.erase(key)
        _zombie_last_sync_state.erase(key)
    var priority_keys: Array = []
    for sync_id_val in all_zombie_keys:
        var character = _sync_characters[sync_id_val]
        if !is_instance_valid(character):
            continue
        var last: Dictionary = _zombie_last_sync_state.get(sync_id_val, {})
        var cur_d: bool = character.instance.die if is_instance_valid(character.instance) else false
        var cur_nd: bool = character.instance.nearDie if is_instance_valid(character.instance) else false
        if cur_d != last.get("d", false) or cur_nd != last.get("nd", false):
            priority_keys.append(sync_id_val)
            continue
        if is_instance_valid(character.sprite) and character.sprite.clip != last.get("c", ""):
            priority_keys.append(sync_id_val)
            continue
        var cur_hp: float = character.instance.hitpoints if is_instance_valid(character.instance) else 0.0
        if absf(cur_hp - last.get("h", 0.0)) > 10.0:
            priority_keys.append(sync_id_val)
            continue
    var batch_keys: Array = []
    if all_zombie_keys.size() <= ZOMBIE_SYNC_BATCH_SIZE:
        batch_keys = all_zombie_keys
    else:
        if _zombie_sync_batch_index == 0 or _zombie_sync_keys.is_empty():
            _zombie_sync_keys = all_zombie_keys.duplicate()
            _zombie_sync_keys.shuffle()
            _zombie_sync_batch_index = 0
        var start: int = _zombie_sync_batch_index * ZOMBIE_SYNC_BATCH_SIZE
        var end: int = mini(start + ZOMBIE_SYNC_BATCH_SIZE, _zombie_sync_keys.size())
        if start >= _zombie_sync_keys.size():
            _zombie_sync_batch_index = 0
            _zombie_sync_keys = all_zombie_keys.duplicate()
            _zombie_sync_keys.shuffle()
            start = 0
            end = mini(ZOMBIE_SYNC_BATCH_SIZE, _zombie_sync_keys.size())
        batch_keys = _zombie_sync_keys.slice(start, end - 1)
        _zombie_sync_batch_index += 1
        if _zombie_sync_batch_index * ZOMBIE_SYNC_BATCH_SIZE >= _zombie_sync_keys.size():
            _zombie_sync_batch_index = 0
    var sync_keys: Dictionary = {}
    for k in priority_keys:
        sync_keys[k] = true
    for k in batch_keys:
        sync_keys[k] = true
    var zombies_data: Array = []
    for sync_id_val in sync_keys.keys():
        var character = _sync_characters.get(sync_id_val)
        if !is_instance_valid(character) or character.isDestroy or !(character is TowerDefenseZombie):
            continue
        var zombie: TowerDefenseZombie = character as TowerDefenseZombie
        var cur_x: float = snappedf(zombie.global_position.x, 0.1)
        var cur_y: float = snappedf(zombie.global_position.y, 0.1)
        var cur_hp: float = zombie.instance.hitpoints if is_instance_valid(zombie.instance) else 0.0
        var cur_nd: bool = zombie.instance.nearDie if is_instance_valid(zombie.instance) else false
        var cur_d: bool = zombie.instance.die if is_instance_valid(zombie.instance) else false
        var cur_ts: float = zombie.timeScale
        var cur_ws: float = zombie.walkSpeedScale
        var cur_clip: String = ""
        var cur_loop: bool = true
        var cur_blend: float = 0.0
        var cur_fi: int = 0
        if is_instance_valid(zombie.sprite):
            cur_clip = zombie.sprite.clip
            cur_loop = zombie.sprite.loop
            cur_blend = zombie.sprite.blendTime
            cur_fi = zombie.sprite.frameIndex
        var last: Dictionary = _zombie_last_sync_state.get(sync_id_val, {})
        var is_priority: bool = priority_keys.has(sync_id_val)
        var zombie_data: Dictionary = {"i": sync_id_val}
        if is_priority or absf(cur_x - last.get("x", 0.0)) > 0.5:
            zombie_data["x"] = cur_x
        if is_priority or absf(cur_y - last.get("y", 0.0)) > 0.5:
            zombie_data["y"] = cur_y
        if is_priority or absf(cur_hp - last.get("h", 0.0)) > 0.5:
            zombie_data["h"] = cur_hp
        if cur_nd:
            zombie_data["nd"] = true
        if cur_d:
            zombie_data["d"] = true
        if is_priority or cur_clip != last.get("c", ""):
            zombie_data["c"] = cur_clip
            if !cur_loop:
                zombie_data["l"] = false
            if cur_blend > 0.01:
                zombie_data["b"] = snappedf(cur_blend, 0.01)
            zombie_data["fi"] = cur_fi
        if is_priority or absf(cur_ts - last.get("ts", 1.0)) > 0.05:
            zombie_data["ts"] = snappedf(cur_ts, 0.01)
        if is_priority or absf(cur_ws - last.get("ws", 1.0)) > 0.05:
            zombie_data["ws"] = snappedf(cur_ws, 0.01)
        if is_instance_valid(zombie.instance) and zombie.instance.damagePointData:
            var cur_dpi: int = zombie.instance.damagePointIndex
            if is_priority or cur_dpi != last.get("dpi", 0):
                zombie_data["dpi"] = cur_dpi
        if is_instance_valid(zombie.instance) and zombie.instance.armorList.size() > 0:
            var armor_changed: bool = false
            var armors_data: Array = []
            var last_armors: Array = last.get("ar", [])
            var armor_remove_list: Array[TowerDefenseArmorInstance] = []
            for ai in zombie.instance.armorList.size():
                var armor: TowerDefenseArmorInstance = zombie.instance.armorList[ai]
                if !is_instance_valid(armor):
                    continue
                if armor.isRemove:
                    var was_present: bool = false
                    for la in last_armors:
                        if la.get("i", -1) == ai and !la.get("rm", false):
                            was_present = true
                            break
                    if was_present or last_armors.is_empty():
                        armors_data.append({"i": ai, "rm": true})
                        armor_changed = true
                    else:
                        armor_remove_list.append(armor)
                    continue
                var a_data: Dictionary = {"i": ai, "hp": snappedf(armor.hitPoints, 0.1), "si": armor.stageIndex}
                armors_data.append(a_data)
                if ai < last_armors.size():
                    if absf(armor.hitPoints - last_armors[ai].get("hp", 0.0)) > 1.0 or armor.stageIndex != last_armors[ai].get("si", 0):
                        armor_changed = true
                else:
                    armor_changed = true
            if is_priority or armor_changed or armors_data.size() != last_armors.size():
                zombie_data["ar"] = armors_data
            for armor_instance: TowerDefenseArmorInstance in armor_remove_list:
                zombie.instance.armorList.erase(armor_instance)
                zombie.instance.armorShield.erase(armor_instance)
                zombie.instance.armorHelm.erase(armor_instance)
                zombie.instance.armorBody.erase(armor_instance)
                zombie.instance.armorHeadCover.erase(armor_instance)
        if is_instance_valid(zombie.buff):
            var buffs_data: Array = []
            for buffKey in zombie.buff.buffDictionary.keys():
                var buff: TowerDefenseCharacterBuffConfig = zombie.buff.buffDictionary[buffKey]
                var b_data: Dictionary = {"k": buffKey}
                if buff.get("time") != null:
                    b_data["t"] = snappedf(buff.get("time"), 0.01)
                if buff.get("currentTime") != null:
                    b_data["ct"] = snappedf(buff.get("currentTime"), 0.01)
                buffs_data.append(b_data)
            var last_bf: Array = last.get("bf", [])
            if is_priority or buffs_data.size() > 0 or last_bf.size() > 0:
                zombie_data["bf"] = buffs_data
        _zombie_last_sync_state[sync_id_val] = {
            "x": cur_x, "y": cur_y, "h": cur_hp, 
            "nd": cur_nd, "d": cur_d, 
            "ts": cur_ts, "ws": cur_ws, 
            "c": cur_clip, "l": cur_loop, "b": cur_blend, 
            "dpi": zombie_data.get("dpi", 0), 
            "ar": zombie_data.get("ar", []), 
            "bf": zombie_data.get("bf", [])
        }
        zombies_data.append(zombie_data)
    if zombies_data.size() > 0 or all_zombie_keys.size() > 0:
        var sync_packet: Dictionary = {
            "z": zombies_data, 
            "a": all_zombie_infos
        }
        MultiPlayerManager.SendZombieFullSync(JSON.stringify(sync_packet))

func _multiplayer_apply_zombie_state(sync_data: Variant) -> void :
    var zombies_data: Variant = sync_data
    var host_all_zombie_ids: Dictionary = {}
    var host_zombie_infos: Dictionary = {}
    if sync_data is Dictionary:
        zombies_data = sync_data.get("z", [])
        var all_ids: Array = sync_data.get("a", [])
        for sid in all_ids:
            if sid is Dictionary:
                var sid_val: int = sid.get("i", -1)
                if sid_val >= 0:
                    host_all_zombie_ids[sid_val] = true
                    host_zombie_infos[sid_val] = sid
            else:
                host_all_zombie_ids[sid] = true
    if !(zombies_data is Array):
        return
    var synced_zombie_ids: Dictionary = {}
    for zombie_data in zombies_data:
        if !(zombie_data is Dictionary):
            continue
        var sync_id_val: int = zombie_data.get("i", zombie_data.get("sync_id", -1))
        if sync_id_val < 0 or !_sync_characters.has(sync_id_val):
            continue
        synced_zombie_ids[sync_id_val] = true
        var character = _sync_characters[sync_id_val]
        if !is_instance_valid(character) or character.isDestroy:
            continue
        if !(character is TowerDefenseZombie):
            continue
        var zombie: TowerDefenseZombie = character as TowerDefenseZombie
        if zombie_data.has("x") or zombie_data.has("y"):
            var target_x: float = zombie_data.get("x", zombie.global_position.x)
            var target_y: float = zombie_data.get("y", zombie.global_position.y)
            var new_target: Vector2 = Vector2(target_x, target_y)
            if _zombie_target_positions.has(sync_id_val):
                var old_target: Vector2 = _zombie_target_positions[sync_id_val]
                var old_time: float = _zombie_last_sync_time.get(sync_id_val, 0.0)
                var time_delta: float = TowerDefenseManager.runGameTime - old_time
                if time_delta > 0.01:
                    _zombie_sync_velocities[sync_id_val] = (new_target - old_target) / time_delta
            _zombie_target_positions[sync_id_val] = new_target
            _zombie_last_sync_time[sync_id_val] = TowerDefenseManager.runGameTime
        if is_instance_valid(zombie.instance):
            if zombie_data.has("h"):
                var sync_hp: float = zombie_data["h"]
                zombie.instance.hitpoints = sync_hp
            var sync_near_die: bool = zombie_data.get("nd", false)
            if sync_near_die and !zombie.instance.nearDie:
                zombie.instance.nearDie = true
                zombie.instance.hitpointsNearDie.emit()
            var sync_die: bool = zombie_data.get("d", false)
            if sync_die and !zombie.instance.die:
                zombie.instance.die = true
                zombie.instance.hitpointsEmpty.emit()
            if !sync_die and zombie.instance.hitpoints <= 0 and !zombie.isDestroy:
                zombie.instance.hitpoints = 1
        var clip_name: String = zombie_data.get("c", "")
        if clip_name != "" and is_instance_valid(zombie.sprite):
            if zombie.sprite.clip != clip_name:
                var loop_anim: bool = zombie_data.get("l", true)
                var blend_time: float = zombie_data.get("b", 0.0)
                zombie.SyncAnimation(clip_name, loop_anim, blend_time)
                if zombie_data.has("fi"):
                    zombie.sprite.frameIndex = zombie_data["fi"]
                    zombie.sprite.elapsedTimer = 0.0
        if zombie_data.has("ts"):
            zombie.timeScale = zombie_data["ts"]
        if zombie_data.has("ws"):
            zombie.walkSpeedScale = zombie_data["ws"]
        if zombie_data.has("dpi") and is_instance_valid(zombie.instance) and zombie.instance.damagePointData:
            var sync_dpi: int = zombie_data["dpi"]
            if sync_dpi > zombie.instance.damagePointIndex:
                for di in range(zombie.instance.damagePointIndex, sync_dpi):
                    if di < zombie.instance.damagePoints.size():
                        var dp_name: String = zombie.instance.damagePoints[di]["Name"]
                        zombie.instance.damagePointData.SetDamagePointFliters(zombie.sprite, dp_name)
                        if zombie.config.customData:
                            for customName: String in zombie.currentCustom:
                                zombie.config.customData.SetDamagePoint(zombie.sprite, customName, di)
                        zombie.DamagePointReach(dp_name)
                zombie.instance.damagePointIndex = sync_dpi
        if zombie_data.has("ar") and is_instance_valid(zombie.instance):
            var armors_data: Array = zombie_data["ar"]
            var armor_remove_list: Array[TowerDefenseArmorInstance] = []
            for a_data in armors_data:
                var armor_idx: int = a_data.get("i", -1)
                if armor_idx < 0 or armor_idx >= zombie.instance.armorList.size():
                    continue
                var armor: TowerDefenseArmorInstance = zombie.instance.armorList[armor_idx]
                if !is_instance_valid(armor):
                    continue
                if a_data.get("rm", false):
                    if !armor.isRemove:
                        if armor.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DROPABLE and !armor.damagePartDropped:
                            zombie.DamagePartCreate(StringName(armor.config.armorName), null, Vector2(randf_range(-100, 100), -300), true, Vector2.ZERO, true)
                        armor.Remove()
                        armor.isRemove = true
                    armor_remove_list.append(armor)
                    continue
                if armor.isRemove:
                    continue
                if a_data.has("hp"):
                    armor.hitPoints = a_data["hp"]
                if a_data.has("si"):
                    var sync_si: int = a_data["si"]
                    if sync_si > armor.stageIndex:
                        for s in range(armor.stageIndex, sync_si):
                            armor.SetDamageStage(s + 1)
                        armor.stageIndex = sync_si
                if armor.hitPoints <= 0 and !armor.isRemove:
                    if armor.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DROPABLE:
                        zombie.DamagePartCreate(StringName(armor.config.armorName), null, Vector2(randf_range(-100, 100), -300), true, Vector2.ZERO, true)
                    armor.Remove()
                    armor.isRemove = true
                    armor_remove_list.append(armor)
            for armor_instance: TowerDefenseArmorInstance in armor_remove_list:
                zombie.instance.armorList.erase(armor_instance)
                zombie.instance.armorShield.erase(armor_instance)
                zombie.instance.armorHelm.erase(armor_instance)
                zombie.instance.armorBody.erase(armor_instance)
                zombie.instance.armorHeadCover.erase(armor_instance)
        if zombie_data.has("bf") and is_instance_valid(zombie.buff):
            zombie.buff.is_syncing = true
            var buffs_data: Array = zombie_data["bf"]
            var synced_keys: Dictionary = {}
            for b_data in buffs_data:
                var buff_key: String = b_data.get("k", "")
                if buff_key == "":
                    continue
                synced_keys[buff_key] = true
                if !zombie.buff.BuffHas(buff_key):
                    var new_buff: TowerDefenseCharacterBuffConfig = TowerDefenseCharacterBuffConfig.CreateBuffByKey(buff_key)
                    if is_instance_valid(new_buff):
                        new_buff.character = zombie
                        zombie.buff.buffDictionary[buff_key] = new_buff
                        new_buff.Enter()
                        if b_data.has("t"):
                            new_buff.set("time", b_data["t"])
                        if b_data.has("ct"):
                            new_buff.set("currentTime", b_data["ct"])
                else:
                    var existing_buff: TowerDefenseCharacterBuffConfig = zombie.buff.buffDictionary[buff_key]
                    if is_instance_valid(existing_buff):
                        if b_data.has("t"):
                            existing_buff.set("time", b_data["t"])
                        if b_data.has("ct"):
                            existing_buff.set("currentTime", b_data["ct"])
            var keys_to_remove: Array = []
            for existing_key in zombie.buff.buffDictionary.keys():
                if !synced_keys.has(existing_key):
                    keys_to_remove.append(existing_key)
            for key in keys_to_remove:
                var remove_buff: TowerDefenseCharacterBuffConfig = zombie.buff.buffDictionary[key]
                if is_instance_valid(remove_buff):
                    remove_buff.Exit()
                zombie.buff.buffDictionary.erase(key)
            zombie.buff.is_syncing = false
    if !MultiPlayerManager.isHost:
        for sid_val in host_zombie_infos.keys():
            if _sync_characters.has(sid_val):
                continue
            var info: Dictionary = host_zombie_infos[sid_val]
            var zombie_name: String = info.get("n", "")
            if zombie_name == "":
                continue
            var zombie_line: int = info.get("g", 1)
            var zombie_x: float = info.get("x", 0.0)
            var zombie_y: float = info.get("y", 0.0)
            var packet_config: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombie_name)
            if !is_instance_valid(packet_config):
                continue
            var zombie = packet_config.Create(Vector2(zombie_x, zombie_y), Vector2i(0, zombie_line), 0)
            if !is_instance_valid(zombie):
                continue
            characterNode.add_child.call_deferred(zombie)
            _register_sync_character(sid_val, zombie)
        var zombie_keys: Array = _sync_characters.keys()
        for sid in zombie_keys:
            if !_sync_characters.has(sid):
                continue
            var c = _sync_characters[sid]
            if !is_instance_valid(c) or c.isDestroy or !(c is TowerDefenseZombie):
                _zombie_sync_miss_count.erase(sid)
                continue
            if host_all_zombie_ids.has(sid) or synced_zombie_ids.has(sid):
                _zombie_sync_miss_count.erase(sid)
            else:
                if !_zombie_sync_miss_count.has(sid):
                    _zombie_sync_miss_count[sid] = 0
                _zombie_sync_miss_count[sid] += 1
                var miss_limit: int = 10
                if _zombie_sync_miss_count[sid] > miss_limit:
                    _zombie_sync_miss_count.erase(sid)
                    _zombie_target_positions.erase(sid)
                    if is_instance_valid(c.destroyComponent):
                        c.destroyComponent.is_remote_destroy = true
                    c.Destroy()

func _multiplayer_interpolate_zombie_positions(delta: float) -> void :
    var invalid_keys: Array = []
    var correction_threshold: float = 15.0
    var snap_threshold: float = 80.0
    var lerp_speed: float = 8.0
    var max_extrapolation_time: float = 0.3
    for sync_id_val in _zombie_target_positions.keys():
        if !_sync_characters.has(sync_id_val):
            invalid_keys.append(sync_id_val)
            continue
        var character = _sync_characters[sync_id_val]
        if !is_instance_valid(character) or character.isDestroy:
            invalid_keys.append(sync_id_val)
            continue
        if !(character is TowerDefenseZombie):
            continue
        var target_pos: Vector2 = _zombie_target_positions[sync_id_val]
        var extrapolated_pos: Vector2 = target_pos
        if _zombie_sync_velocities.has(sync_id_val) and _zombie_last_sync_time.has(sync_id_val):
            var velocity: Vector2 = _zombie_sync_velocities[sync_id_val]
            var time_since_sync: float = TowerDefenseManager.runGameTime - _zombie_last_sync_time[sync_id_val]
            if time_since_sync > 0.0 and time_since_sync < max_extrapolation_time:
                extrapolated_pos = target_pos + velocity * time_since_sync
        var offset: Vector2 = extrapolated_pos - character.global_position
        var dist: float = offset.length()
        if dist > snap_threshold:
            character.global_position = extrapolated_pos
        elif dist > correction_threshold:
            character.global_position = character.global_position.lerp(extrapolated_pos, lerp_speed * delta)
    for key in invalid_keys:
        _zombie_target_positions.erase(key)
        _zombie_sync_velocities.erase(key)
        _zombie_last_sync_time.erase(key)
