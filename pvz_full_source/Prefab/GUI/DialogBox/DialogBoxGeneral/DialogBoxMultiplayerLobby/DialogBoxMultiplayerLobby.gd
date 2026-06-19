extends DialogPopup

enum State{SELECT_MODE, INPUT_IP, IN_ROOM}

@onready var _status_label: RichTextLabel = %StatusLabel
@onready var _room_id_label: RichTextLabel = %RoomIdLabel
@onready var _peer_list_label: RichTextLabel = %PeerListLabel
@onready var _create_button: TextureButton = %CreateButton
@onready var _close_button: TextureButton = %CloseButton
@onready var _room_id_input: LineEdit = %RoomIdInput
@onready var _confirm_join_button: TextureButton = %ConfirmJoinButton
@onready var _hbox: HBoxContainer = $Layer / Control / HBox
@onready var _hbox2: HBoxContainer = $Layer / Control / HBox2
@onready var _hbox3: HBoxContainer = $Layer / Control / HBox3

var _state: State = State.SELECT_MODE

func _ready() -> void :
    super._ready()
    MultiPlayerManager.match_created.connect(_on_match_created)
    MultiPlayerManager.match_joined.connect(_on_match_joined)
    MultiPlayerManager.match_left.connect(_on_match_left)
    MultiPlayerManager.peer_joined.connect(_on_peer_joined)
    MultiPlayerManager.peer_left.connect(_on_peer_left)
    if MultiPlayerManager.currentMatchId != "":
        _state = State.IN_ROOM
    _update_ui_state()

func _set_state(new_state: State) -> void :
    _state = new_state
    _update_ui_state()

func _update_ui_state() -> void :
    _hbox.visible = _state == State.SELECT_MODE
    _hbox3.visible = _state == State.INPUT_IP
    _hbox2.visible = _state == State.IN_ROOM
    _room_id_input.visible = _state == State.INPUT_IP
    _room_id_label.visible = _state == State.IN_ROOM
    _peer_list_label.visible = _state == State.IN_ROOM

    match _state:
        State.SELECT_MODE:
            _status_label.clear()
            _status_label.append_text("[center]创建或加入房间开始联机[/center]")

        State.INPUT_IP:
            _status_label.clear()
            _status_label.append_text("[center]输入房主的IP地址[/center]")

        State.IN_ROOM:
            if MultiPlayerManager.isHost:
                _status_label.clear()
                _status_label.append_text("[center]你是房主 — 关闭此窗口后自由选关[/center]")
                _room_id_label.clear()
                var ips = MultiPlayerManager.GetAllLanIps()
                var port = MultiPlayerManager._current_port
                if ips.is_empty():
                    _room_id_label.append_text("[center]未检测到可用IP[/center]")
                else:
                    var ip_text = ""
                    for ip in ips:
                        if ip_text != "":
                            ip_text += "\n"
                        ip_text += "%s:%d" % [ip, port]
                    _room_id_label.append_text("[center]%s[/center]" % ip_text)
                _close_button.visible = true
            else:
                _status_label.clear()
                _status_label.append_text("[center]已加入房间 — 等待房主选关[/center]")
                _room_id_label.clear()
                _room_id_label.append_text("[center]主机: %s[/center]" % MultiPlayerManager.currentMatchId)
                _close_button.visible = false

            _peer_list_label.clear()
            _peer_list_label.append_text("[center]在线人数: %d[/center]" % MultiPlayerManager.matchMembers.size())

func _on_create_button_pressed() -> void :
    _create_button.disabled = true
    MultiPlayerManager.CreateMatch()
    _create_button.disabled = false
    if MultiPlayerManager.currentMatchId != "":
        _set_state(State.IN_ROOM)

func _on_join_button_pressed() -> void :
    _set_state(State.INPUT_IP)

func _on_confirm_join_button_pressed() -> void :
    var address: String = _room_id_input.text.strip_edges()
    if address == "":
        BroadCastManager.BroadCastFloatCreate("请输入IP地址", Color.RED)
        return
    _confirm_join_button.disabled = true
    MultiPlayerManager.JoinMatch(address)
    _confirm_join_button.disabled = false
    if MultiPlayerManager.currentMatchId != "":
        _set_state(State.IN_ROOM)

func _on_cancel_join_button_pressed() -> void :
    _set_state(State.SELECT_MODE)

func _on_leave_button_pressed() -> void :
    await MultiPlayerManager.LeaveMatch()
    _set_state(State.SELECT_MODE)

@warning_ignore("unused_parameter")
func _on_match_created(match_id: String) -> void :
    _set_state(State.IN_ROOM)

@warning_ignore("unused_parameter")
func _on_match_joined(match_id: String) -> void :
    _set_state(State.IN_ROOM)

func _on_match_left() -> void :
    _set_state(State.SELECT_MODE)

func _on_peer_joined(username: String) -> void :
    _update_ui_state()
    BroadCastManager.BroadCastFloatCreate("%s 加入了房间" % username, Color.GREEN)

func _on_peer_left(username: String, _peer_id: String) -> void :
    _update_ui_state()
    BroadCastManager.BroadCastFloatCreate("%s 离开了房间" % username, Color.RED)
