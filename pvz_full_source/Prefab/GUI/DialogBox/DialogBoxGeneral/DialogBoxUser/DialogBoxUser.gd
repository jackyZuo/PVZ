extends DialogPopup

const userItemScene = preload("uid://xo7n1bu85swf")
const userButtonGroup = preload("uid://dge7tb6et4lw7")

@onready var userContainer: VBoxContainer = %UserContainer
@onready var renameButton: MainButton = %RenameButton
@onready var finishButton: MainButton = %FinishButton
@onready var deleteButton: MainButton = %DeleteButton
@onready var cancelButton: MainButton = %CancelButton
@onready var createUserButton: Button = %CreateUserButton
@onready var logOutButton: MainButton = %LogOutButton
@onready var backButton: MainButton = %BackButton

var editUser: String = ""
func _ready() -> void :
    super._ready()
    RefreshUser()
    InternetServerManager.share_level_success.connect(_on_share_level_success)
    InternetServerManager.share_level_failed.connect(_on_share_level_failed)



func RefreshUser():
    for node in userContainer.get_children():
        node.queue_free()

    for user in GameSaveManager.GetUserList():
        UserItemCreate(user)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    deleteButton.disabled = GameSaveManager.GetUserList().size() <= 1

func UserItemCreate(user: String):
    var userItem = userItemScene.instantiate() as UserItem
    if GameSaveManager.GetUserCurrent() == user:
        editUser = user
        userItem.button_pressed = true
    userItem.text = user
    userItem.choose.connect(UserChange)
    userItem.button_group = userButtonGroup
    userContainer.add_child(userItem)

func UserChange(user: String) -> void :
    editUser = user

func RenameButtonPressed() -> void :
    var dialog = DialogCreate("RenameUser")
    dialog.changeUser = editUser
    dialog.close.connect(RenameDialogClose)

func RenameDialogClose() -> void :
    RefreshUser()

func FinishButtonPressed() -> void :
    GameSaveManager.SetUserCurrent(editUser)
    GameSaveManager.Save()
    Close()

func DeleteButtonPressed() -> void :
    var dialog = DialogCreate("DeleteUser")
    dialog.deleteUser = editUser
    dialog.close.connect(DeleteDialogClose)

func DeleteDialogClose() -> void :
    if !GameSaveManager.HasUser(editUser):
        userContainer.get_children()[0].button_pressed = true
        editUser = userContainer.get_children()[0].text
        RefreshUser()

func CancelButtonPressed() -> void :
    GameSaveManager.SetUserCurrent(editUser)
    GameSaveManager.Save()
    Close()

func CreateUserButtonPressed() -> void :
    var dialog = DialogCreate("NewUser")
    dialog.close.connect(CreateUserDialogClose)

func CreateUserDialogClose() -> void :
    RefreshUser()
    editUser = GameSaveManager.GetUserCurrent()

func LogOutButtonPressed() -> void :
    MultiPlayerManager.LogOut()
    Close()

func BackButtonPressed() -> void :
    SceneManager.ChangeScene("Loading", true)
    Close()

func ExportButtonPressed() -> void :
    @warning_ignore("unused_parameter")
    DisplayServer.file_dialog_show("保存存档文件", "", "", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, ["*.res"], 
        func SaveFileTo(status: bool, selectedPaths: PackedStringArray, selectedFilterIndex: int) -> void :
            if selectedPaths.size() > 0:
                if selectedPaths[0].get_extension() != "res":
                    selectedPaths[0] += ".res"
                ResourceSaver.save(GameSaveManager.config, selectedPaths[0])
    )

func LoadButtonPressed() -> void :
    @warning_ignore("unused_parameter")
    DisplayServer.file_dialog_show("打开存档文件", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.res"], 
        func FileOpen(status: bool, selectedPaths: PackedStringArray, selectedFilterIndex: int) -> void :
            if selectedPaths.size() > 0:
                match selectedPaths[0].get_extension():
                    "res":
                        var res = load(selectedPaths[0])
                        if res is GameSaveConfig:
                            var chooseDialog = DialogManager.DialogCreate("DialogBoxChoose")
                            chooseDialog.text = "[center][font_size=24]是否导入该存档？[/font_size][/center]"
                            chooseDialog.chooseTrue.connect(
                                func():
                                    GameSaveManager.config = res
                                    RefreshUser()
                                    GameSaveManager.SetUserCurrent(editUser)
                                    GameSaveManager.Save()
                            )
                        else:
                            var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
                            tipsDialog.text = "[center][font_size=24]该文件不是存档文件[/font_size][/center]"
    )


func InternetExportButtoPressed() -> void :
    if editUser != "" && GameSaveManager.config.saveDictionary.has(editUser):
        var chooseDialog = DialogManager.DialogCreate("DialogBoxChoose")
        chooseDialog.text = "[center][font_size=24]确定要分享该存档吗？[/font_size][/center]"
        chooseDialog.chooseTrue.connect(
            func():
                var user_data: Dictionary = GameSaveManager.config.saveDictionary[editUser]
                var json_string: String = JSON.stringify(user_data)
                var bytes: PackedByteArray = json_string.to_utf8_buffer().compress(FileAccess.CompressionMode.COMPRESSION_GZIP)
                InternetServerManager.ShareLevel(bytes)
        )
    else:
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]无法获取当前用户数据[/font_size][/center]"

func InternetLoadButtonPressed() -> void :
    var inputDialog = DialogManager.DialogCreate("DialogBoxInput")
    inputDialog.titleText = "[center][font_size=24]输入分享码[/font_size][/center]"
    inputDialog.inputMaxLength = 4
    inputDialog.inputDefaultText = ""
    inputDialog.inputPlaceholder = "请输入4位分享码"
    inputDialog.confirmButtonPressed.connect(
        func():
            var code: String = inputDialog.inputText.strip_edges()
            if code.length() == 4:
                InternetServerManager.get_shared_level_success.connect(_on_get_shared_level_success)
                InternetServerManager.get_shared_level_failed.connect(_on_get_shared_level_failed)
                InternetServerManager.GetSharedFile(code)
            else:
                var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
                tipsDialog.text = "[center][font_size=24]请输入4位分享码[/font_size][/center]"
    )

var pending_import_data: Dictionary = {}

func _on_get_shared_level_success(data: PackedByteArray) -> void :
    InternetServerManager.get_shared_level_success.disconnect(_on_get_shared_level_success)
    InternetServerManager.get_shared_level_failed.disconnect(_on_get_shared_level_failed)
    var json_string: String = data.decompress_dynamic(-1, FileAccess.CompressionMode.COMPRESSION_GZIP).get_string_from_utf8()
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result == OK && json.data is Dictionary:
        pending_import_data = json.get_data()

        _show_import_name_input()
    else:
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]数据格式错误[/font_size][/center]"

func _show_import_name_input() -> void :
    var inputDialog = DialogManager.DialogCreate("DialogBoxInput")
    inputDialog.titleText = "[center][font_size=24]导入存档[/font_size][/center]"
    inputDialog.inputMaxLength = 20
    inputDialog.inputDefaultText = ""
    inputDialog.inputPlaceholder = "请输入存档名称"
    inputDialog.confirmButtonPressed.connect(
        func():
            var user_name: String = inputDialog.inputText.strip_edges()
            if user_name.length() > 0:
                if GameSaveManager.HasUser(user_name):
                    var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
                    tipsDialog.text = "[center][font_size=24]该用户名已存在[/font_size][/center]"
                else:
                    _import_to_new_user(user_name)
            else:
                var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
                tipsDialog.text = "[center][font_size=24]请输入存档名称[/font_size][/center]"
    )

func _import_to_new_user(user_name: String) -> void :
    GameSaveManager.config.userList.append(user_name)
    GameSaveManager.config.saveDictionary[user_name] = pending_import_data.duplicate(true)
    GameSaveManager.Save()
    RefreshUser()
    pending_import_data.clear()
    var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
    tipsDialog.text = "[center][font_size=24]导入成功[/font_size][/center]"

func _on_get_shared_level_failed(message: String) -> void :
    InternetServerManager.get_shared_level_success.disconnect(_on_get_shared_level_success)
    InternetServerManager.get_shared_level_failed.disconnect(_on_get_shared_level_failed)
    var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
    tipsDialog.text = "[center][font_size=24]%s[/font_size][/center]" % message

@warning_ignore("unused_parameter")
func _on_share_level_success(code: String, expireAt: int, expireSeconds: int) -> void :
    var timezone = Time.get_time_zone_from_system()
    var local_expire_at = expireAt + timezone.bias * 60
    var date_time = Time.get_datetime_dict_from_unix_time(local_expire_at)
    var time_str = "%02d:%02d:%02d" % [date_time.hour, date_time.minute, date_time.second]
    var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
    tipsDialog.text = "[center][font_size=16]分享成功！\n分享码: %s\n过期时间: %s[/font_size][/center]" % [code, time_str]

func _on_share_level_failed(message: String) -> void :
    var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
    tipsDialog.text = "[center][font_size=24]分享失败: %s[/font_size][/center]" % message
