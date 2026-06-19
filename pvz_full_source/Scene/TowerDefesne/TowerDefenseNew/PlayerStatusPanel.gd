extends Control

const PLAYER_COLORS: Array[Color] = [
    Color(0.3, 0.7, 1.0), 
    Color(1.0, 0.5, 0.3), 
    Color(0.5, 1.0, 0.5), 
    Color(1.0, 1.0, 0.3), 
]

const SIGNAL_BAR_FULL: String = "■"
const SIGNAL_BAR_EMPTY: String = "□"

@onready var _player_list: VBoxContainer = %PlayerList

var _player_rows: Dictionary = {}

func _ready() -> void :
    visible = false
    if MultiPlayerManager:
        MultiPlayerManager.ping_updated.connect(_on_ping_updated)
        MultiPlayerManager.peer_joined.connect(_on_peer_changed)
        MultiPlayerManager.peer_left.connect(_on_peer_left)
        MultiPlayerManager.match_left.connect(_on_match_left)

func _process(_delta: float) -> void :
    if !visible:
        return
    _refresh_all_rows()

func ShowPanel() -> void :
    visible = true
    _rebuild_rows()

func HidePanel() -> void :
    visible = false

func _rebuild_rows() -> void :
    for child in _player_list.get_children():
        child.queue_free()
    _player_rows.clear()
    if !MultiPlayerManager or !Global.isMultiplayerMode:
        return
    var members: Array = MultiPlayerManager.matchMembers.duplicate()
    if !members.has(MultiPlayerManager.peerId):
        members.push_front(MultiPlayerManager.peerId)
    for i in range(members.size()):
        var member_id: String = members[i]
        var row: HBoxContainer = _create_player_row(member_id, i)
        _player_list.add_child(row)
        _player_rows[member_id] = row

func _create_player_row(peer_id_str: String, index: int) -> HBoxContainer:
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    row.custom_minimum_size = Vector2(340.0, 28.0)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var color_rect: ColorRect = ColorRect.new()
    color_rect.custom_minimum_size = Vector2(4.0, 20.0)
    color_rect.color = PLAYER_COLORS[index % PLAYER_COLORS.size()]
    color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(color_rect)
    var name_label: Label = Label.new()
    var player_name: String = MultiPlayerManager.GetPeerName(peer_id_str) if MultiPlayerManager else "Player"
    name_label.text = player_name
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
    name_label.custom_minimum_size = Vector2(120.0, 0.0)
    name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(name_label)
    var signal_label: Label = Label.new()
    signal_label.add_theme_font_size_override("font_size", 16)
    signal_label.custom_minimum_size = Vector2(110.0, 0.0)
    signal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(signal_label)
    var latency_label: Label = Label.new()
    latency_label.add_theme_font_size_override("font_size", 16)
    latency_label.custom_minimum_size = Vector2(80.0, 0.0)
    latency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    latency_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(latency_label)
    _update_row_data(row, peer_id_str)
    return row

func _update_row_data(row: HBoxContainer, peer_id_str: String) -> void :
    var children: Array = row.get_children()
    if children.size() < 4:
        return
    var signal_label: Label = children[2] as Label
    var latency_label: Label = children[3] as Label
    if !MultiPlayerManager:
        return
    var latency: int = MultiPlayerManager.GetPeerLatency(peer_id_str)
    var signal_level: int = MultiPlayerManager.GetSignalLevel(peer_id_str)
    var signal_text: String = ""
    var signal_color: Color
    for j in range(5):
        if j < signal_level:
            signal_text += SIGNAL_BAR_FULL
        else:
            signal_text += SIGNAL_BAR_EMPTY
    signal_text += " "
    match signal_level:
        5:
            signal_color = Color(0.3, 1.0, 0.3)
            signal_text += "极好"
        4:
            signal_color = Color(0.5, 1.0, 0.5)
            signal_text += "良好"
        3:
            signal_color = Color(1.0, 1.0, 0.3)
            signal_text += "一般"
        2:
            signal_color = Color(1.0, 0.6, 0.2)
            signal_text += "较差"
        1:
            signal_color = Color(1.0, 0.3, 0.3)
            signal_text += "极差"
        _:
            signal_color = Color(0.5, 0.5, 0.5)
            signal_text += "无信号"
    signal_label.text = signal_text
    signal_label.add_theme_color_override("font_color", signal_color)
    if latency > 0:
        latency_label.text = str(latency) + " ms"
        if latency <= 50:
            latency_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
        elif latency <= 100:
            latency_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
        elif latency <= 200:
            latency_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
        elif latency <= 400:
            latency_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
        else:
            latency_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
    else:
        latency_label.text = "--- ms"
        latency_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

func _refresh_all_rows() -> void :
    for peer_id_str in _player_rows:
        var row: HBoxContainer = _player_rows[peer_id_str]
        if is_instance_valid(row):
            _update_row_data(row, peer_id_str)

func _on_ping_updated(peer_id: String, _latency_ms: int) -> void :
    if !visible:
        return
    if _player_rows.has(peer_id):
        var row: HBoxContainer = _player_rows[peer_id]
        if is_instance_valid(row):
            _update_row_data(row, peer_id)

func _on_peer_changed(_username: String) -> void :
    if visible:
        _rebuild_rows()

func _on_peer_left(_username: String, _peer_id: String) -> void :
    if visible:
        _rebuild_rows()

func _on_match_left() -> void :
    visible = false
    for child in _player_list.get_children():
        child.queue_free()
    _player_rows.clear()
