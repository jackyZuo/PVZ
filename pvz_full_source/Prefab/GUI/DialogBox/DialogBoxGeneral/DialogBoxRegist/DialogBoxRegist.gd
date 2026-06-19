extends DialogPopup

@onready var nameLineEdit: LineEdit = %NameLineEdit
@onready var emailLineEdit: LineEdit = %EmailLineEdit
@onready var passwordLineEdit: LineEdit = %PasswordLineEdit
@onready var passwordLineEdit2: LineEdit = %PasswordLineEdit2

func _ready() -> void :
    super._ready()
    emailLineEdit.visible = false
    passwordLineEdit.visible = false
    passwordLineEdit2.visible = false

func RegistButtonPressed() -> void :
    var player_name: String = nameLineEdit.text.strip_edges()
    if player_name == "":
        BroadCastManager.BroadCastFloatCreate("请输入玩家名称", Color.RED)
        return
    @warning_ignore("redundant_await")
    var regist: bool = await MultiPlayerManager.Regist("", "", player_name)
    if regist:
        Close()

func CancelButtonPressed() -> void :
    Close()
