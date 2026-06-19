extends Node

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 4

var _peer: ENetMultiplayerPeer = null
var _player_name: String = ""

var currentMatchId: String = ""
var isHost: bool = false
var peerId: String = ""
var matchMembers: Array = []
var selectedLevelId: String = ""

var _received_level_config_json: String = ""
var _received_level_config_type: String = ""
var _received_level_enter_mode: String = ""
var _received_level_is_battle: bool = false

var _peer_names: Dictionary = {}
var _clients_ready: Array = []
@warning_ignore("unused_signal")
signal all_clients_ready()
var _level_config_acked: Array = []
signal all_level_config_acked()
var _game_entry_acked: Array = []
@warning_ignore("unused_signal")
signal all_game_entry_acked()
var _game_entry_sent: bool = false

signal login_success
signal match_created(match_id: String)
signal match_joined(match_id: String)
signal match_left
signal peer_joined(username: String)
signal peer_left(username: String, peer_id: String)
signal match_state_received(op_code: String, data: String, sender_id: String)
signal connection_changed(connected: bool)
signal ping_updated(peer_id: String, latency_ms: int)

var _ping_send_times: Dictionary = {}
var _peer_latencies: Dictionary = {}
var _ping_timer: float = 0.0
const PING_INTERVAL: float = 2.0

func _process(delta: float) -> void :
    if currentMatchId == "" or !_peer:
        return
    _ping_timer += delta
    if _ping_timer >= PING_INTERVAL:
        _ping_timer = 0.0
        _send_ping()

func GetPeerLatency(peer_id_str: String) -> int:
    return _peer_latencies.get(peer_id_str, 0)

func GetSignalLevel(peer_id_str: String) -> int:
    var latency: int = _peer_latencies.get(peer_id_str, 999)
    if latency <= 50:
        return 5
    elif latency <= 100:
        return 4
    elif latency <= 200:
        return 3
    elif latency <= 400:
        return 2
    elif latency <= 800:
        return 1
    return 0

func _send_ping() -> void :
    var send_time: float = Time.get_ticks_msec()
    var ping_id: String = peerId + "_" + str(send_time)
    _ping_send_times[ping_id] = send_time
    var current_time: float = Time.get_ticks_msec()
    var keys_to_remove: Array = []
    for key in _ping_send_times:
        if current_time - _ping_send_times[key] > 10000:
            keys_to_remove.append(key)
    for key in keys_to_remove:
        _ping_send_times.erase(key)
    if isHost:
        _peer_latencies[peerId] = 0
        ping_updated.emit(peerId, 0)
        for member_id in matchMembers:
            if int(member_id) != 1:
                _rpc_ping.rpc_id(int(member_id), ping_id)
    else:
        _rpc_ping.rpc_id(1, ping_id)

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_ping(ping_id: String) -> void :
    var sender_id = str(multiplayer.get_remote_sender_id())
    _rpc_pong.rpc_id(int(sender_id), ping_id)

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_pong(ping_id: String) -> void :
    var sender_id = str(multiplayer.get_remote_sender_id())
    if !_ping_send_times.has(ping_id):
        return
    var send_time: float = _ping_send_times[ping_id]
    var latency: int = int(Time.get_ticks_msec() - send_time)
    if !isHost:
        _ping_send_times.erase(ping_id)
    _peer_latencies[sender_id] = latency
    ping_updated.emit(sender_id, latency)
    if isHost:
        var results: Dictionary = {}
        results[peerId] = 0
        for member_id in matchMembers:
            results[member_id] = _peer_latencies.get(member_id, 0)
        _rpc_ping_result.rpc(JSON.stringify(results))

@rpc("authority", "call_remote", "reliable")
func _rpc_ping_result(data: String) -> void :
    var parsed = JSON.parse_string(data)
    if parsed is Dictionary:
        for key in parsed:
            _peer_latencies[key] = parsed[key]
            ping_updated.emit(key, parsed[key])

func _ready() -> void :
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func Login(player_name: String = "Player", _password: String = "") -> bool:
    _player_name = player_name
    peerId = str(multiplayer.get_unique_id())
    BroadCastManager.BroadCastFloatCreate("LOGIN_SUCCESS", Color.GREEN)
    login_success.emit()
    connection_changed.emit(true)
    return true

func Regist(_email: String, _password: String, userName: String) -> bool:
    return Login(userName)

func LogOut() -> bool:
    if currentMatchId != "":
        LeaveMatch()
    _player_name = ""
    peerId = ""
    matchMembers.clear()
    _peer_names.clear()
    _ping_send_times.clear()
    _peer_latencies.clear()
    _ping_timer = 0.0
    connection_changed.emit(false)
    match_left.emit()
    return true

func IsConnect() -> bool:
    return _player_name != ""

func GetUserName() -> String:
    return _player_name

func GetUserDisplayName() -> String:
    return _player_name

func GetPeerName(peer_id_str: String) -> String:
    var id: int = int(peer_id_str)
    if _peer_names.has(id):
        return _peer_names[id]
    return "P%s" % peer_id_str

var _current_port: int = DEFAULT_PORT

func CreateMatch() -> bool:
    _peer = ENetMultiplayerPeer.new()
    var error = _peer.create_server(_current_port, MAX_PLAYERS)
    if error != OK:
        _current_port = DEFAULT_PORT + 1
        _peer = ENetMultiplayerPeer.new()
        error = _peer.create_server(_current_port, MAX_PLAYERS)
    if error != OK:
        BroadCastManager.BroadCastFloatCreate("CREATE_MATCH_FAILED", Color.RED)
        _peer = null
        return false
    multiplayer.multiplayer_peer = _peer
    isHost = true
    currentMatchId = "host"
    peerId = str(multiplayer.get_unique_id())
    _player_name = GameSaveManager.GetUserCurrent() if GameSaveManager.GetUserCurrent() != "" else "Host"
    Global.isMultiplayerMode = true
    Global.isMultiplayerHost = true
    matchMembers.clear()
    matchMembers.append(peerId)
    _peer_names.clear()
    match_created.emit(currentMatchId)
    BroadCastManager.BroadCastFloatCreate("ROOM_CREATED", Color.GREEN)
    return true

func JoinMatch(address: String) -> bool:
    var parts = address.split(":")
    var host: String = parts[0]
    var port: int = int(parts[1]) if parts.size() > 1 else DEFAULT_PORT
    _peer = ENetMultiplayerPeer.new()
    var error = _peer.create_client(host, port)
    if error != OK:
        BroadCastManager.BroadCastFloatCreate("JOIN_MATCH_FAILED", Color.RED)
        return false
    multiplayer.multiplayer_peer = _peer
    isHost = false
    currentMatchId = address
    peerId = str(multiplayer.get_unique_id())
    _player_name = GameSaveManager.GetUserCurrent() if GameSaveManager.GetUserCurrent() != "" else "Client"
    Global.isMultiplayerMode = true
    Global.isMultiplayerHost = false
    matchMembers.clear()
    matchMembers.append(peerId)
    _peer_names.clear()
    return true

func LeaveMatch() -> void :
    if currentMatchId == "":
        return
    if _peer:
        _peer.close()
        await get_tree().process_frame
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    _peer = null
    currentMatchId = ""
    isHost = false
    _current_port = DEFAULT_PORT
    Global.isMultiplayerMode = false
    Global.isMultiplayerHost = false
    _player_name = ""
    matchMembers.clear()
    _peer_names.clear()
    _ping_send_times.clear()
    _peer_latencies.clear()
    _ping_timer = 0.0
    match_left.emit()

func SendMatchState(opCode: String, data: String) -> void :
    if currentMatchId == "":
        return
    if isHost:
        _rpc_receive_match_state.rpc(opCode, data)
        _process_match_state(opCode, data, peerId)
    else:
        _rpc_receive_match_state.rpc_id(1, opCode, data)

func SendMatchStateUnreliable(opCode: String, data: String) -> void :
    if currentMatchId == "":
        return
    if isHost:
        _rpc_receive_match_state_unreliable.rpc(opCode, data)
        _process_match_state(opCode, data, peerId)
    else:
        _rpc_receive_match_state_unreliable.rpc_id(1, opCode, data)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_receive_match_state(op_code: String, data: String) -> void :
    var sender_id = str(multiplayer.get_remote_sender_id())
    _process_match_state(op_code, data, sender_id)

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_receive_match_state_unreliable(op_code: String, data: String) -> void :
    var sender_id = str(multiplayer.get_remote_sender_id())
    if isHost:
        _rpc_receive_match_state_unreliable.rpc(op_code, data)
    match_state_received.emit(op_code, data, sender_id)

func _process_match_state(op_code: String, data: String, sender_id: String) -> void :
    match op_code:
        MatchOpCodes.START_GAME:
            _handle_start_game(data)
        MatchOpCodes.SELECT_LEVEL:
            _handle_select_level(data)
        MatchOpCodes.LEVEL_CONFIG:
            _handle_level_config(data)
        MatchOpCodes.LEVEL_CONFIG_ACK:
            if isHost:
                var parsed = JSON.parse_string(data)
                if parsed and parsed.has("user_id"):
                    var user_id: String = parsed["user_id"]
                    if !_level_config_acked.has(user_id):
                        _level_config_acked.append(user_id)
                    if CheckAllLevelConfigAcked():
                        all_level_config_acked.emit()
        MatchOpCodes.CHOOSE_READY:
            if isHost and sender_id != peerId:
                _rpc_receive_match_state.rpc(op_code, data)
            match_state_received.emit(op_code, data, sender_id)
        MatchOpCodes.CHOOSE_OVER:
            match_state_received.emit(op_code, data, sender_id)
        MatchOpCodes.PLACE_PLANT:
            match_state_received.emit(op_code, data, sender_id)
        _:
            if sender_id != peerId:
                if isHost:
                    _rpc_receive_match_state.rpc(op_code, data)
                match_state_received.emit(op_code, data, sender_id)

func SendSelectLevel(levelId: String) -> void :
    selectedLevelId = levelId
    var difficult: String = GameSaveManager.GetKeyValue("CurrentDifficult") if GameSaveManager else "Normal"
    var level_uid: String = _find_level_uid(levelId, difficult)
    var data = JSON.stringify({"level_id": levelId, "user_id": peerId, "difficult": difficult, "level_uid": level_uid})
    SendMatchState(MatchOpCodes.SELECT_LEVEL, data)

func SendLevelConfig() -> void :
    if !isHost:
        return
    var config = TowerDefenseManager.currentLevelConfig
    if !is_instance_valid(config):
        return
    var config_type: String = ""
    var config_json: String = ""
    if config is TowerDefenseLevelConfig:
        config_type = "TowerDefenseLevelConfig"
        if config.data and config.data.data is Dictionary:
            config_json = JSON.stringify(config.data.data)
        else:
            config.ExportToFeatureProcess()
            config_json = JSON.stringify({"Feature": _serialize_features(config.featureData), "Process": {"Name": config.processName, "Data": config.processData}, "Name": config.name, "LevelName": config.levelName, "Description": config.description, "LevelNumber": config.levelNumber, "BaseTimeScale": config.baseTimeScale})
    elif config is TowerDefenseLevelNewConfig:
        config_type = "TowerDefenseLevelNewConfig"
        if config.data and config.data.data is Dictionary:
            config_json = JSON.stringify(config.data.data)
        else:
            config_json = JSON.stringify({"Feature": _serialize_features(config.featureData), "Process": {"Name": config.processName, "Data": config.processData}, "Name": config.name, "LevelName": config.levelName, "Description": config.description, "LevelNumber": config.levelNumber, "Version": config.version})
    else:
        return
    var data = JSON.stringify({
        "config_type": config_type, 
        "config_json": config_json, 
        "enter_level_mode": Global.enterLevelMode, 
        "enter_level_is_battle": Global.enterLevelIsBattle
    })
    SendMatchState(MatchOpCodes.LEVEL_CONFIG, data)

func _serialize_features(feature_data: Dictionary) -> Array:
    var arr: Array = []
    for feature_name: StringName in feature_data:
        arr.append({"Name": feature_name, "Data": feature_data[feature_name]})
    return arr

func _find_level_uid(level_id: String, difficult: String) -> String:
    for mode_key in ResourceManager.LEVELS:
        var mode_data = ResourceManager.LEVELS[mode_key]
        if !(mode_data is Dictionary) or !mode_data.has("Chapter"):
            continue
        var chapters = mode_data["Chapter"]
        for chapter in chapters:
            if !chapter.has("Level"):
                continue
            for level in chapter["Level"]:
                if level.get("SaveKey", "") != level_id:
                    continue
                var level_data = level.get("Level", {})
                if level_data is Dictionary:
                    var uid: String = level_data.get(difficult, "")
                    if uid != "" and ResourceLoader.exists(uid):
                        return uid
                    uid = level_data.get("Normal", "")
                    if uid != "" and ResourceLoader.exists(uid):
                        return uid
    return ""

func SendStartGame() -> void :
    if !isHost:
        return
    var difficult: String = GameSaveManager.GetKeyValue("CurrentDifficult") if GameSaveManager else "Normal"
    var level_uid: String = _find_level_uid(selectedLevelId, difficult)
    var data = JSON.stringify({"level_id": selectedLevelId, "difficult": difficult, "level_uid": level_uid})
    SendMatchState(MatchOpCodes.START_GAME, data)

func SendPlacePlant(plantName: String, gridX: int, gridY: int, syncId: int = -1, overrideData: String = "") -> void :
    var data = JSON.stringify({
        "plant_name": plantName, 
        "grid_x": gridX, 
        "grid_y": gridY, 
        "sync_id": syncId, 
        "user_id": peerId, 
        "override_data": overrideData
    })
    SendMatchState(MatchOpCodes.PLACE_PLANT, data)

func SendRemovePlant(gridX: int, gridY: int) -> void :
    var data = JSON.stringify({
        "grid_x": gridX, 
        "grid_y": gridY, 
        "user_id": peerId
    })
    SendMatchState(MatchOpCodes.REMOVE_PLANT, data)

func SendCollectSun(sunInstanceId: int) -> void :
    var data = JSON.stringify({
        "sun_instance_id": sunInstanceId, 
        "user_id": peerId
    })
    SendMatchState(MatchOpCodes.COLLECT_SUN, data)

func SendGameStateSync(state: Dictionary) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.GAME_STATE_SYNC, JSON.stringify(state))

func SendSpawnZombie(zombieName: String, line: int, offsetX: float, syncId: int, spawnOverrideData: String = "", spawnConfigOverrideData: String = "") -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "zombie_name": zombieName, 
        "line": line, 
        "offset_x": offsetX, 
        "sync_id": syncId, 
        "user_id": peerId, 
        "spawn_override": spawnOverrideData, 
        "spawn_config_override": spawnConfigOverrideData
    })
    SendMatchState(MatchOpCodes.SPAWN_ZOMBIE, data)

func SendSpawnGrid(packetName: String, gridX: int, gridY: int, syncId: int) -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "packet_name": packetName, 
        "grid_x": gridX, 
        "grid_y": gridY, 
        "sync_id": syncId, 
        "user_id": peerId
    })
    SendMatchState(MatchOpCodes.SPAWN_GRID, data)

func SendGameResult(victory: bool) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.GAME_RESULT, JSON.stringify({"victory": victory}))

func SendCharacterDestroy(syncId: int, isExplode: bool = false, isSmash: bool = false) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.CHARACTER_DESTROY, JSON.stringify({"sync_id": syncId, "is_explode": isExplode, "is_smash": isSmash}))

func SendCharacterInit(syncId: int, posX: float, posY: float, hp: float, die: bool, clipName: String = "", loopAnim: bool = true, blendTimeVal: float = 0.0, frameIndexVal: int = 0, timeScaleVal: float = 1.0, walkSpeedScaleVal: float = 1.0) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.CHARACTER_INIT, JSON.stringify({
        "sync_id": syncId, 
        "x": posX, 
        "y": posY, 
        "hp": hp, 
        "die": die, 
        "clip": clipName, 
        "loop": loopAnim, 
        "blendTime": blendTimeVal, 
        "frame": frameIndexVal, 
        "timeScale": timeScaleVal, 
        "walkSpeedScale": walkSpeedScaleVal
    }))

func SendCharacterStateSync(charactersData: String) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.CHARACTER_STATE_SYNC, charactersData)

func SendCharacterPositionSync(syncId: int, posX: float, posY: float) -> void :
    if !isHost:
        return
    SendMatchStateUnreliable(MatchOpCodes.CHARACTER_POSITION_SYNC, JSON.stringify({
        "sync_id": syncId, 
        "x": posX, 
        "y": posY
    }))

func SendZombieFullSync(zombiesData: String) -> void :
    if !isHost:
        return
    SendMatchStateUnreliable(MatchOpCodes.ZOMBIE_FULL_SYNC, zombiesData)

func SendCursorSync(posX: float, posY: float) -> void :
    SendMatchStateUnreliable(MatchOpCodes.CURSOR_SYNC, JSON.stringify({
        "x": posX, 
        "y": posY, 
        "user_id": peerId
    }))

func SendCursorPickSync(pickType: String, pickName: String) -> void :
    SendMatchState(MatchOpCodes.CURSOR_PICK_SYNC, JSON.stringify({
        "pickType": pickType, 
        "pickName": pickName, 
        "user_id": peerId
    }))

func SendChooseReady() -> void :
    SendMatchState(MatchOpCodes.CHOOSE_READY, JSON.stringify({
        "user_id": peerId
    }))

func SendChooseOver() -> void :
    SendMatchState(MatchOpCodes.CHOOSE_OVER, JSON.stringify({}))

func SendVaseBreakRequest(gridX: int, gridY: int) -> void :
    var data = JSON.stringify({
        "grid_x": gridX, 
        "grid_y": gridY, 
        "user_id": peerId
    })
    SendMatchState(MatchOpCodes.VASE_BREAK_REQUEST, data)

func SendVaseBreakResult(breakData: Dictionary) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.VASE_BREAK, JSON.stringify(breakData))

func SendPacketSpawn(syncId: int, packetName: String, posX: float, posY: float, aliveTime: float, isFall: bool, useCost: bool, velocityX: float, velocityY: float, zIndex: int, fallHeight: float = 0.0) -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "sync_id": syncId, 
        "packet_name": packetName, 
        "pos_x": posX, 
        "pos_y": posY, 
        "alive_time": aliveTime, 
        "is_fall": isFall, 
        "use_cost": useCost, 
        "velocity_x": velocityX, 
        "velocity_y": velocityY, 
        "z_index": zIndex, 
        "fall_height": fallHeight
    })
    SendMatchState(MatchOpCodes.PACKET_SPAWN, data)

func SendPacketPick(syncId: int, pickType: String = "remove") -> void :
    var data = JSON.stringify({
        "sync_id": syncId, 
        "pick_type": pickType, 
        "user_id": peerId
    })
    SendMatchState(MatchOpCodes.PACKET_PICK, data)

func SendPause() -> void :
    SendMatchState(MatchOpCodes.PAUSE, JSON.stringify({"user_id": peerId}))

func SendResume() -> void :
    SendMatchState(MatchOpCodes.RESUME, JSON.stringify({"user_id": peerId}))

func SendSpawnSun(sunType: String, posX: float, posY: float, sunNum: int, velocityX: float, velocityY: float, gravity: float, height: float, moveStopTime: float, movingMethod: int) -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "sun_type": sunType, 
        "pos_x": posX, 
        "pos_y": posY, 
        "sun_num": sunNum, 
        "velocity_x": velocityX, 
        "velocity_y": velocityY, 
        "gravity": gravity, 
        "height": height, 
        "move_stop_time": moveStopTime, 
        "moving_method": movingMethod
    })
    SendMatchState(MatchOpCodes.SPAWN_SUN, data)

func SendSpawnCoin(posX: float, posY: float, num: int, velocityX: float, velocityY: float, gravity: float, height: float, collect: bool) -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "pos_x": posX, 
        "pos_y": posY, 
        "num": num, 
        "velocity_x": velocityX, 
        "velocity_y": velocityY, 
        "gravity": gravity, 
        "height": height, 
        "collect": collect
    })
    SendMatchState(MatchOpCodes.SPAWN_COIN, data)

func SendSpawnFallingObject(posX: float, posY: float, velocityX: float, velocityY: float, gravity: float, height: float) -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "pos_x": posX, 
        "pos_y": posY, 
        "velocity_x": velocityX, 
        "velocity_y": velocityY, 
        "gravity": gravity, 
        "height": height
    })
    SendMatchState(MatchOpCodes.SPAWN_FALLING_OBJECT, data)

func SendSpawnCharacterAt(packetName: String, gridX: int, gridY: int, syncId: int, hitpointScale: float = 1.0, scaleVal: float = 1.0, hypnoses: bool = false, riseDuration: float = 0.0, useCreate: bool = false, posX: float = 0.0, posY: float = 0.0, walkAfterSpawn: bool = false, groundHeight: float = 0.0, sizeVal: String = "") -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "packet_name": packetName, 
        "grid_x": gridX, 
        "grid_y": gridY, 
        "sync_id": syncId, 
        "hitpoint_scale": hitpointScale, 
        "scale": scaleVal, 
        "hypnoses": hypnoses, 
        "rise_duration": riseDuration, 
        "use_create": useCreate, 
        "pos_x": posX, 
        "pos_y": posY, 
        "walk_after_spawn": walkAfterSpawn, 
        "ground_height": groundHeight, 
        "size": sizeVal, 
        "user_id": peerId
    })
    SendMatchState(MatchOpCodes.SPAWN_CHARACTER_AT, data)

func SendConveyorSpawn(packetName: String, packetType: String) -> void :
    if !isHost:
        return
    var data = JSON.stringify({
        "packet_name": packetName, 
        "packet_type": packetType, 
        "user_id": peerId
    })
    SendMatchState(MatchOpCodes.CONVEYOR_SPAWN, data)

func SendClientReady() -> void :
    if isHost:
        return
    SendMatchState(MatchOpCodes.CLIENT_READY, JSON.stringify({"user_id": peerId}))

func SendGameEntry(round_num: int) -> void :
    if !isHost:
        return
    _game_entry_sent = true
    SendMatchState(MatchOpCodes.GAME_ENTRY, JSON.stringify({"round_num": round_num}))

func SendTipsPlay(text: String, duration: float) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.TIPS_PLAY, JSON.stringify({"text": text, "duration": duration}))

func SendDamagePart(sync_id: int, part_name: String, pos_x: float, pos_y: float, velocity_x: float, velocity_y: float) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.DAMAGE_PART, JSON.stringify({"sync_id": sync_id, "part_name": part_name, "px": pos_x, "py": pos_y, "vx": velocity_x, "vy": velocity_y}))

func SendDamagePointReach(sync_id: int, damage_point_name: String) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.DAMAGE_POINT_REACH, JSON.stringify({"sync_id": sync_id, "damage_point_name": damage_point_name}))

func SendArmorDamagePointReach(sync_id: int, armor_name: String, stage: int) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.ARMOR_DAMAGE_POINT_REACH, JSON.stringify({"sync_id": sync_id, "armor_name": armor_name, "stage": stage}))

func SendArmorHitpointsEmpty(sync_id: int, armor_name: String) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.ARMOR_HITPOINTS_EMPTY, JSON.stringify({"sync_id": sync_id, "armor_name": armor_name}))

func SendCraterCreate(grid_x: int, grid_y: int, crater_name: String) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.CRATER_CREATE, JSON.stringify({"grid_x": grid_x, "grid_y": grid_y, "crater_name": crater_name}))

func SendPlantFullSync(plants_data: String) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.PLANT_FULL_SYNC, plants_data)

func SendEventExecute(phase: String, events_data: String) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.EVENT_EXECUTE, JSON.stringify({"phase": phase, "events": events_data}))

func SendWaveEventExecute(waveId: int, events_data: String) -> void :
    if !isHost:
        return
    SendMatchState(MatchOpCodes.WAVE_EVENT_EXECUTE, JSON.stringify({"wave_id": waveId, "events": events_data}))

func ResetClientsReady() -> void :
    _clients_ready.clear()

func CheckAllClientsReady() -> bool:
    var clients: Array = matchMembers.duplicate()
    clients.erase("1")
    if clients.size() == 0:
        return true
    for client_id in clients:
        if !_clients_ready.has(client_id):
            return false
    return true

func SendLevelConfigAck() -> void :
    if isHost:
        return
    SendMatchState(MatchOpCodes.LEVEL_CONFIG_ACK, JSON.stringify({"user_id": peerId}))

func ResetLevelConfigAck() -> void :
    _level_config_acked.clear()

func CheckAllLevelConfigAcked() -> bool:
    var clients: Array = matchMembers.duplicate()
    clients.erase("1")
    if clients.size() == 0:
        return true
    for client_id in clients:
        if !_level_config_acked.has(client_id):
            return false
    return true

func SendGameEntryAck() -> void :
    if isHost:
        return
    SendMatchState(MatchOpCodes.GAME_ENTRY_ACK, JSON.stringify({"user_id": peerId}))

func ResetGameEntryAck() -> void :
    _game_entry_acked.clear()
    _game_entry_sent = false

func CheckAllGameEntryAcked() -> bool:
    var clients: Array = matchMembers.duplicate()
    clients.erase("1")
    if clients.size() == 0:
        return true
    for client_id in clients:
        if !_game_entry_acked.has(client_id):
            return false
    return true

func GetMatchIdShort() -> String:
    if currentMatchId == "":
        return ""
    if isHost:
        var lan_ip = _get_lan_ip()
        return lan_ip + ":" + str(_current_port)
    return currentMatchId

func _get_lan_ip() -> String:
    var addresses = IP.get_local_addresses()
    var candidates: PackedStringArray = []
    for addr in addresses:
        if addr == "127.0.0.1":
            continue
        if ":" in addr:
            continue
        if addr.begins_with("169.254"):
            continue
        if addr.begins_with("172."):
            var second = addr.split(".")[1].to_int()
            if second >= 16 and second <= 31:
                continue
        candidates.append(addr)
    for addr in candidates:
        if addr.begins_with("192.168."):
            return addr
    for addr in candidates:
        if addr.begins_with("10."):
            return addr
    if candidates.size() > 0:
        return candidates[0]
    return "127.0.0.1"

func GetAllLanIps() -> PackedStringArray:
    var addresses = IP.get_local_addresses()
    var result: PackedStringArray = []
    for addr in addresses:
        if addr == "127.0.0.1":
            continue
        if ":" in addr:
            continue
        if addr.begins_with("169.254"):
            continue
        if addr.begins_with("172."):
            var second = addr.split(".")[1].to_int()
            if second >= 16 and second <= 31:
                continue
        result.append(addr)
    return result

func _on_peer_connected(id: int) -> void :
    if isHost:
        if matchMembers.size() >= MAX_PLAYERS:
            _peer.disconnect_peer(id)
            return
        if !matchMembers.has(str(id)):
            matchMembers.append(str(id))
        peer_joined.emit("Player")
        var names_data: Dictionary = {}
        for nid in _peer_names:
            names_data[str(nid)] = _peer_names[nid]
        _rpc_send_host_info.rpc_id(id, _player_name, matchMembers, Global.version, names_data)
        for member_id in matchMembers:
            if int(member_id) != 1 and int(member_id) != id:
                _rpc_sync_members.rpc_id(int(member_id), matchMembers)

@rpc("authority", "call_remote", "reliable")
func _rpc_send_host_info(host_name: String, members: Array, host_version: String, names_data: Dictionary) -> void :
    _peer_names.clear()
    _peer_names[1] = host_name
    for key in names_data:
        _peer_names[int(key)] = names_data[key]
    matchMembers = members
    if host_version != Global.version:
        BroadCastManager.BroadCastFloatCreate("版本不一致，无法连接", Color.RED)
        _rpc_version_mismatch.rpc_id(1, Global.version)
        await get_tree().create_timer(0.5).timeout
        _cleanup_connection()
        return
    peer_joined.emit(host_name)
    _rpc_send_client_name.rpc_id(1, _player_name)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_version_mismatch(client_version: String) -> void :
    var sender_id = multiplayer.get_remote_sender_id()
    var sender_name = _peer_names.get(sender_id, "Client")
    BroadCastManager.BroadCastFloatCreate("%s 版本不一致(%s)，已断开" % [sender_name, client_version], Color.RED)

@rpc("authority", "call_remote", "reliable")
func _rpc_sync_members(members: Array) -> void :
    matchMembers = members
    peer_joined.emit("Player")

@rpc("any_peer", "call_remote", "reliable")
func _rpc_send_client_name(player_name: String) -> void :
    var sender_id = multiplayer.get_remote_sender_id()
    _peer_names[sender_id] = player_name
    peer_joined.emit(player_name)
    _broadcast_peer_names()

func _broadcast_peer_names() -> void :
    if !isHost:
        return
    var names_data: Dictionary = {}
    for id in _peer_names:
        names_data[str(id)] = _peer_names[id]
    names_data["1"] = _player_name
    _rpc_sync_peer_names.rpc(names_data)

@rpc("authority", "call_remote", "reliable")
func _rpc_sync_peer_names(names_data: Dictionary) -> void :
    _peer_names.clear()
    for key in names_data:
        _peer_names[int(key)] = names_data[key]

func _on_peer_disconnected(id: int) -> void :
    var player_name = _peer_names.get(id, "Player")
    var pid = str(id)
    matchMembers.erase(pid)
    _peer_names.erase(id)
    peer_left.emit(player_name, pid)

func _on_connected_to_server() -> void :
    match_joined.emit(currentMatchId)
    BroadCastManager.BroadCastFloatCreate("JOINED_ROOM", Color.GREEN)

func _on_connection_failed() -> void :
    BroadCastManager.BroadCastFloatCreate("JOIN_MATCH_FAILED", Color.RED)
    _cleanup_connection()

func _on_server_disconnected() -> void :
    BroadCastManager.BroadCastFloatCreate("HOST_DISCONNECTED", Color.RED)
    _cleanup_connection()

func _cleanup_connection() -> void :
    if _peer:
        _peer.close()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    _peer = null
    currentMatchId = ""
    isHost = false
    _player_name = ""
    matchMembers.clear()
    _peer_names.clear()
    Global.isMultiplayerMode = false
    Global.isMultiplayerHost = false
    connection_changed.emit(false)
    match_left.emit()

func _handle_start_game(data: String) -> void :
    var parsed = JSON.parse_string(data)
    if !parsed:
        return
    selectedLevelId = parsed.get("level_id", "")
    var difficult: String = parsed.get("difficult", "Normal")
    var level_uid: String = parsed.get("level_uid", "")
    Global.enterLevelMode = _received_level_enter_mode if _received_level_enter_mode != "" else "Multiplayer"
    Global.enterLevelId = selectedLevelId
    Global.enterLevelIsBattle = _received_level_is_battle
    Global.isMultiplayerMode = true
    Global.isMultiplayerHost = isHost
    if !isHost:
        TowerDefenseManager.currentLevelConfig = null
        if _received_level_config_json != "":
            _create_level_config_from_received()
        else:
            if level_uid != "" and ResourceLoader.exists(level_uid):
                TowerDefenseManager.currentLevelConfig = load(level_uid)
            else:
                _load_level_by_id(selectedLevelId, difficult)
    await get_tree().process_frame
    SceneManager.ChangeScene("TowerDefense")

func _load_level_by_id(level_id: String, difficult: String = "Normal") -> void :
    for mode_key in ResourceManager.LEVELS:
        var mode_data = ResourceManager.LEVELS[mode_key]
        if !(mode_data is Dictionary) or !mode_data.has("Chapter"):
            continue
        var chapters = mode_data["Chapter"]
        for chapter in chapters:
            if !chapter.has("Level"):
                continue
            for level in chapter["Level"]:
                if level.has("SaveKey") and level["SaveKey"] == level_id:
                    var level_data = level.get("Level", {})
                    if level_data is Dictionary:
                        var level_uid: String = level_data.get(difficult, "")
                        if level_uid == "" or !ResourceLoader.exists(level_uid):
                            level_uid = level_data.get("Normal", "")
                        if level_uid != "" and ResourceLoader.exists(level_uid):
                            TowerDefenseManager.currentLevelConfig = load(level_uid)
                        return

func _handle_select_level(data: String) -> void :
    var parsed = JSON.parse_string(data)
    if !parsed:
        return
    selectedLevelId = parsed.get("level_id", "")

func _handle_level_config(data: String) -> void :
    var parsed = JSON.parse_string(data)
    if !parsed:
        return
    _received_level_config_type = parsed.get("config_type", "")
    _received_level_enter_mode = parsed.get("enter_level_mode", "")
    _received_level_is_battle = parsed.get("enter_level_is_battle", false)
    _received_level_config_json = parsed.get("config_json", "")
    if !isHost:
        SendLevelConfigAck()

func _create_level_config_from_received() -> void :
    if _received_level_config_json == "":
        return
    match _received_level_config_type:
        "TowerDefenseLevelConfig":
            var json = JSON.new()
            if json.parse(_received_level_config_json) == OK:
                var config = TowerDefenseLevelConfig.new()
                config.data = json
                TowerDefenseManager.currentLevelConfig = config
        "TowerDefenseLevelNewConfig":
            var json = JSON.new()
            if json.parse(_received_level_config_json) == OK:
                var config = TowerDefenseLevelNewConfig.new()
                config.data = json
                TowerDefenseManager.currentLevelConfig = config
    _received_level_config_json = ""
    _received_level_config_type = ""
    _received_level_enter_mode = ""
    _received_level_is_battle = false
