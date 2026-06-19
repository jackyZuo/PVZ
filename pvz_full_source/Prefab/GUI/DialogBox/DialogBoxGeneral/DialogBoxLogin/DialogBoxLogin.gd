extends DialogPopup

@onready var emailLineEdit: LineEdit = %EmailLineEdit
@onready var passwordLineEdit: LineEdit = %PasswordLineEdit

func _ready() -> void :
    super._ready()
    passwordLineEdit.visible = false

func LoginButtonPressed() -> void :
    var player_name: String = emailLineEdit.text.strip_edges()
    if player_name == "":
        BroadCastManager.BroadCastFloatCreate("请输入玩家名称", Color.RED)
        return
    @warning_ignore("redundant_await")
    var login: bool = await MultiPlayerManager.Login(player_name)
    if login:
        Close()

func RegistButtonPressed() -> void :
    Close()

func CancleButtonPressed() -> void :
    Close()
