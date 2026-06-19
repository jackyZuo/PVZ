extends Control

const PATH: String = "user://Diy"
const IZ_ICON = preload("uid://ciyj1718ypbih")
const IZ2_ICON = preload("uid://b8rsot26eb7od")
const VB_ICON = preload("uid://24j6iw1ww08b")

@onready var nameLabel: Label = %NameLabel
@onready var mapTexture: TextureRect = %MapTexture
@onready var iconTexture: TextureRect = %IconTexture

signal select(_uid: String)
signal delete(_uid: String)

var uid: String

var levelConfig: TowerDefenseLevelConfig

func Init(_uid: String) -> void :
    uid = _uid
    var filePath: String = PATH + "/" + uid + ".tres"
    var res = load(filePath)
    if res is TowerDefenseLevelConfig:
        levelConfig = res
        nameLabel.text = levelConfig.levelName
        var mapConfig: TowerDefenseMapConfig = TowerDefenseManager.GetMapConfig(levelConfig.map)
        mapTexture.texture = mapConfig.mapTexture

    match levelConfig.finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
            iconTexture.visible = false
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            iconTexture.visible = true
            iconTexture.texture = VB_ICON
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            iconTexture.visible = true
            iconTexture.texture = IZ_ICON
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
            iconTexture.visible = true
            iconTexture.texture = IZ2_ICON

func DeleteButtonPressed() -> void :
    var dialog = DialogManager.DialogCreate("MyLevelDelete")
    var _uid = uid
    dialog.pressDelete.connect(
        func():
            delete.emit(_uid)
            queue_free()
    )

func SelectButtonPressed() -> void :
    select.emit(uid)
