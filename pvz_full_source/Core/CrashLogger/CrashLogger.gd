extends Node

const _MARKER_DIR: String = "user://crash_internal"
const CRASH_REPORT_DIR_NAME: String = "PVZHE_CrashReports"
const MAX_CRASH_REPORTS: int = 10

var _crash_marker_path: String = ""
var _freeze_marker_path: String = ""
var _state_snapshot_path: String = ""
var _crash_report_dir: String = ""

var _session_start_time: int = 0
var _last_snapshot_time: int = 0
var _snapshot_interval: int = 30
var _marker_written: bool = false

var _heartbeat_ticks: int = 0
var _watchdog_thread: Thread = null
var _watchdog_active: bool = false
var _watchdog_timeout_sec: int = 10
var _freeze_detected_by_watchdog: bool = false

signal crash_detected(report_path: String)

func _ready() -> void :
    if Engine.is_editor_hint():
        set_process(false)
        return
    _InitPaths()
    _session_start_time = Time.get_ticks_msec()
    _heartbeat_ticks = _session_start_time
    _CheckPreviousCrash()
    _WriteCrashMarker()
    _EnsureDir(_crash_report_dir)
    _EnsureDir(_MARKER_DIR)
    get_window().close_requested.connect(_OnCleanQuit)
    _StartWatchdog()
    print("[CrashLogger] 会话已启动，闪退监控已启用（看门狗超时: %ds）" % _watchdog_timeout_sec)
    print("[CrashLogger] 崩溃报告目录: %s" % _crash_report_dir)

func _InitPaths() -> void :
    _crash_marker_path = _MARKER_DIR + "/crash_marker.json"
    _freeze_marker_path = _MARKER_DIR + "/freeze_marker.json"
    _state_snapshot_path = _MARKER_DIR + "/crash_state_snapshot.json"
    if OS.get_name() == "Android":
        var docs_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
        _crash_report_dir = docs_dir + "/" + CRASH_REPORT_DIR_NAME
    else:
        _crash_report_dir = "user://" + CRASH_REPORT_DIR_NAME

func _process(_delta: float) -> void :
    _heartbeat_ticks = Time.get_ticks_msec()
    if !_marker_written:
        return
    var now: int = Time.get_ticks_msec()
    if now - _last_snapshot_time > _snapshot_interval * 1000:
        _last_snapshot_time = now
        _WriteStateSnapshot()

func _notification(what: int) -> void :
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        return
    if what == NOTIFICATION_EXIT_TREE:
        _StopWatchdog()
    if what == NOTIFICATION_OS_MEMORY_WARNING:
        push_warning("[CrashLogger] 检测到低内存警告！")
        print("[CrashLogger] 低内存警告 - 当前场景: %s" % _GetCurrentSceneName())

func _OnCleanQuit() -> void :
    _RemoveFile(_crash_marker_path)
    _RemoveFile(_freeze_marker_path)
    _StopWatchdog()
    print("[CrashLogger] 正常退出，已清除闪退标记")

func _StartWatchdog() -> void :
    _watchdog_active = true
    _watchdog_thread = Thread.new()
    _watchdog_thread.start(_WatchdogLoop)

func _StopWatchdog() -> void :
    _watchdog_active = false
    if _watchdog_thread and _watchdog_thread.is_started():
        _watchdog_thread.wait_to_finish()
    _watchdog_thread = null

func _WatchdogLoop() -> void :
    while _watchdog_active:
        OS.delay_msec(2000)
        if !_watchdog_active:
            break
        var current_ticks: int = Time.get_ticks_msec()
        var elapsed: float = (current_ticks - _heartbeat_ticks) / 1000.0
        if elapsed > _watchdog_timeout_sec and !_freeze_detected_by_watchdog:
            _freeze_detected_by_watchdog = true
            _OnFreezeDetected(elapsed)

func _OnFreezeDetected(elapsed: float) -> void :
    var freeze_info: Dictionary = {
        "freeze_detected_time": _GetTimestamp(), 
        "main_thread_frozen_seconds": elapsed, 
        "session_start": _GetSessionStartTimestamp(), 
    }
    var snapshot: Dictionary = _ReadJsonFile(_state_snapshot_path)
    if !snapshot.is_empty():
        freeze_info["last_state_snapshot"] = snapshot
    _WriteJsonFile(_freeze_marker_path, freeze_info)
    print("[CrashLogger] 看门狗检测到主线程冻结！已写入冻结标记（卡死 %.1f 秒）" % elapsed)

func _GetSessionStartTimestamp() -> String:
    var marker: Dictionary = _ReadJsonFile(_crash_marker_path)
    return marker.get("session_start", "unknown")

func _WriteCrashMarker() -> void :
    var marker: Dictionary = {
        "session_start": _GetTimestamp(), 
        "session_start_ticks": _session_start_time, 
        "godot_version": Engine.get_version_info().get("string", ""), 
        "os_name": OS.get_name(), 
        "game_version": Global.version if is_instance_valid(Global) else "unknown", 
    }
    if _WriteJsonFile(_crash_marker_path, marker):
        _marker_written = true

func _WriteStateSnapshot() -> void :
    var snapshot: Dictionary = _CollectGameState()
    _WriteJsonFile(_state_snapshot_path, snapshot)

func _CollectGameState() -> Dictionary:
    var state: Dictionary = {
        "timestamp": _GetTimestamp(), 
        "uptime_seconds": (Time.get_ticks_msec() - _session_start_time) / 1000.0, 
        "current_scene": _GetCurrentSceneName(), 
        "fps": Engine.get_frames_per_second(), 
        "static_memory_usage_mb": OS.get_static_memory_usage() / 1048576.0, 
    }
    if is_instance_valid(TowerDefenseManager.currentControl):
        state["in_battle"] = true
        state["game_running"] = TowerDefenseManager.currentControl.isGameRunning
        state["game_time"] = TowerDefenseManager.runGameTime
        if TowerDefenseManager.currentControl.levelConfig:
            state["level_name"] = TowerDefenseManager.currentControl.levelConfig.name
    else:
        state["in_battle"] = false
    if is_instance_valid(Global):
        state["is_multiplayer"] = Global.isMultiplayerMode
        state["current_chapter"] = Global.currentChapterId
        state["current_level"] = Global.currentLevelId
        state["time_scale"] = Global.timeScale
        state["anime_frame_rate"] = Global.animeFrameRate
    return state

func _CheckPreviousCrash() -> void :
    var had_freeze: bool = FileAccess.file_exists(_freeze_marker_path)
    var had_crash: bool = FileAccess.file_exists(_crash_marker_path)
    if !had_freeze and !had_crash:
        return
    var marker: Dictionary = _ReadJsonFile(_crash_marker_path)
    var freeze_marker: Dictionary = _ReadJsonFile(_freeze_marker_path)
    var snapshot: Dictionary = _ReadJsonFile(_state_snapshot_path)
    var report: Dictionary = {
        "crash_time": _GetTimestamp(), 
        "session_start": marker.get("session_start", "unknown"), 
        "godot_version": marker.get("godot_version", "unknown"), 
        "os_name": marker.get("os_name", "unknown"), 
        "game_version": marker.get("game_version", "unknown"), 
        "crash_type": "unknown", 
        "last_state_snapshot": snapshot, 
        "godot_log_path": _GetGodotLogPath(), 
    }
    if had_freeze and !freeze_marker.is_empty():
        report["crash_type"] = "freeze"
        report["freeze_detected_time"] = freeze_marker.get("freeze_detected_time", "unknown")
        report["main_thread_frozen_seconds"] = freeze_marker.get("main_thread_frozen_seconds", 0)
        if freeze_marker.has("last_state_snapshot"):
            report["freeze_last_state_snapshot"] = freeze_marker["last_state_snapshot"]
        print("[CrashLogger] 检测到上次会话卡死（可能为while无限循环）！主线程冻结 %.1f 秒" % freeze_marker.get("main_thread_frozen_seconds", 0))
    elif had_crash and !marker.is_empty():
        report["crash_type"] = "crash"
        print("[CrashLogger] 检测到上次会话闪退！")
    else:
        _RemoveFile(_crash_marker_path)
        _RemoveFile(_freeze_marker_path)
        return
    var report_path: String = _SaveCrashReport(report)
    _CopyGodotLogToReportDir()
    _RemoveFile(_crash_marker_path)
    _RemoveFile(_freeze_marker_path)
    _CleanupOldReports()
    print("[CrashLogger] 崩溃报告已保存: %s" % report_path)
    crash_detected.emit(report_path)

func _SaveCrashReport(report: Dictionary) -> String:
    _EnsureDir(_crash_report_dir)
    var timestamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
    var report_path: String = _crash_report_dir + "/crash_%s.json" % timestamp
    _WriteJsonFile(report_path, report)
    return report_path

func _CopyGodotLogToReportDir() -> void :
    var log_src: String = _GetGodotLogPath()
    if !FileAccess.file_exists(log_src):
        return
    var src_file: FileAccess = FileAccess.open(log_src, FileAccess.READ)
    if !src_file:
        return
    var content: String = src_file.get_as_text()
    src_file.close()
    var timestamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
    var log_dst: String = _crash_report_dir + "/godot_%s.log" % timestamp
    var dst_file: FileAccess = FileAccess.open(log_dst, FileAccess.WRITE)
    if dst_file:
        dst_file.store_string(content)
        dst_file.close()

func _CleanupOldReports() -> void :
    var dir: DirAccess = DirAccess.open(_crash_report_dir)
    if !dir:
        return
    var reports: PackedStringArray = []
    dir.list_dir_begin()
    var file_name: String = dir.get_next()
    while file_name != "":
        if file_name.begins_with("crash_") and file_name.ends_with(".json"):
            reports.append(file_name)
        file_name = dir.get_next()
    dir.list_dir_end()
    reports.sort()
    while reports.size() > MAX_CRASH_REPORTS:
        var oldest: String = reports[0]
        reports.remove_at(0)
        _RemoveFile(_crash_report_dir + "/" + oldest)
        var oldest_log: String = oldest.replace("crash_", "godot_").replace(".json", ".log")
        _RemoveFile(_crash_report_dir + "/" + oldest_log)

func _GetCurrentSceneName() -> String:
    if !is_instance_valid(get_tree()) or !get_tree().current_scene:
        return "unknown"
    return get_tree().current_scene.name

func _GetGodotLogPath() -> String:
    return OS.get_user_data_dir() + "/logs/godot.log"

func _GetTimestamp() -> String:
    return Time.get_datetime_string_from_system()

func _EnsureDir(path: String) -> void :
    if !DirAccess.dir_exists_absolute(path):
        DirAccess.make_dir_recursive_absolute(path)

func _RemoveFile(path: String) -> void :
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)

func _WriteJsonFile(path: String, data: Dictionary) -> bool:
    var dir_path: String = path.get_base_dir()
    _EnsureDir(dir_path)
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))
        file.close()
        return true
    return false

func _ReadJsonFile(path: String) -> Dictionary:
    if !FileAccess.file_exists(path):
        return {}
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if !file:
        return {}
    var content: String = file.get_as_text()
    file.close()
    var json: JSON = JSON.new()
    if json.parse(content) != OK:
        return {}
    return json.data if json.data is Dictionary else {}

func HasPreviousCrash() -> bool:
    return false

func GetCrashReports() -> PackedStringArray:
    var reports: PackedStringArray = []
    var dir: DirAccess = DirAccess.open(_crash_report_dir)
    if !dir:
        return reports
    dir.list_dir_begin()
    var file_name: String = dir.get_next()
    while file_name != "":
        if file_name.begins_with("crash_") and file_name.ends_with(".json"):
            reports.append(_crash_report_dir + "/" + file_name)
        file_name = dir.get_next()
    dir.list_dir_end()
    reports.sort()
    reports.reverse()
    return reports

func GetLatestCrashReport() -> Dictionary:
    var reports: PackedStringArray = GetCrashReports()
    if reports.is_empty():
        return {}
    return _ReadJsonFile(reports[0])

func GetGodotLogPath() -> String:
    return _GetGodotLogPath()

func GetCrashReportDir() -> String:
    return _crash_report_dir

func SetWatchdogTimeout(seconds: int) -> void :
    _watchdog_timeout_sec = seconds
