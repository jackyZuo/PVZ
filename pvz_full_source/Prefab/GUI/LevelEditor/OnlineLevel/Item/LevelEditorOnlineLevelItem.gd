extends Control

const PATH: String = "user://OnlineLevel"
const IZ_ICON = preload("uid://ciyj1718ypbih")
const IZ2_ICON = preload("uid://b8rsot26eb7od")
const VB_ICON = preload("uid://24j6iw1ww08b")
const ENDLESS_ICON = preload("uid://bcjx34t665il2")
const SURVIVAL_ICON = preload("uid://crvtrh32bqu0r")
const LUCKY_ICON = preload("uid://caqbmeu30cbsa")

@onready var nameLabel: Label = %NameLabel
@onready var mapTexture: TextureRect = %MapTexture
@onready var finishTexture: TextureRect = %FinishTexture
@onready var hBoxContainer: HBoxContainer = %HBoxContainer
@onready var centerContainer: CenterContainer = %CenterContainer

@export var isBattle: bool = false
@export var cost: int = 1000

signal select(_url: String, _id: String)

var id: String
var lucky: bool = false

func Init(data: Dictionary) -> void :
    centerContainer.visible = false
    for child in hBoxContainer.get_children():
        child.queue_free()
    await get_tree().process_frame
    id = data.get("id", "-1")
    nameLabel.text = data.get("name", "")
    lucky = data.get("lucky", false)
    var mapConfig: TowerDefenseMapConfig = TowerDefenseManager.GetMapConfig(data.get("map", "Frontlawn"))
    mapTexture.texture = mapConfig.mapTexture
    var _levelName: String = "OnlineLevel-%s" % id
    var _levelData: Dictionary = GameSaveManager.GetLevelValue(_levelName)
    if _levelData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0:
        finishTexture.visible = true
    match data.get("finishMethod", "WAVE").to_upper():
        "WAVE":
            centerContainer.visible = false
            if data.has("survivalRoundlimit") && data.get("survivalRoundlimit") != null:
                var survivalRoundlimit: int = data.get("survivalRoundlimit", -1)
                if survivalRoundlimit == -1:
                    centerContainer.visible = true
                    AddIconTexture(ENDLESS_ICON)
                elif survivalRoundlimit >= 0:
                    centerContainer.visible = true
                    AddIconTexture(SURVIVAL_ICON)
        "VASE":
            centerContainer.visible = true
            AddIconTexture(VB_ICON)
        "IZM":
            centerContainer.visible = true
            AddIconTexture(IZ_ICON)
        "IZM2":
            centerContainer.visible = true
            AddIconTexture(IZ2_ICON)
    if lucky:
        centerContainer.visible = true
        AddIconTexture(LUCKY_ICON)

func SelectButtonPressed() -> void :
    if isBattle:
        if TowerDefenseManager.GetCoin() < cost:
            var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
            tipsDialog.text = "[center][font_size=24]您的金币不足[/font_size][/center]"
            return
    var dialog = DialogManager.DialogCreate("OnlineLevelPreview")
    dialog.InitDialog(id)
    dialog.select.connect(EmitSelect)

func EmitSelect(url: String) -> void :
    select.emit(url, id)

func AddIconTexture(iconTexture: Texture2D):
    if hBoxContainer.get_child_count() >= 2:
        return
    var textureRect: TextureRect = TextureRect.new()
    textureRect.texture = iconTexture
    textureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    textureRect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
    textureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hBoxContainer.add_child(textureRect)
