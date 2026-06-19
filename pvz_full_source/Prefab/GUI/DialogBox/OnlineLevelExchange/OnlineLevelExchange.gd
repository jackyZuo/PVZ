extends DialogBoxBase

const ONLINE_LEVEL_EXCHANGE_RESOURCE = preload("res://Asset/Config/OnlineLevelExchange/OnlineLevelExchangeResource.json")

@onready var dragMenu: DragMenu = %DragMenu
@onready var costLabel: Label = %CostLabel
@onready var exchangeButton: TextureButton = %ExchangeButton
@onready var crystalNumLabel: Label = %CrystalNumLabel
@onready var readpaperTexture: TextureRect = %ReadpaperTexture

var currentGroup: String

func _ready() -> void :
    super._ready()
    Setup()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :

    var exchangeData = ONLINE_LEVEL_EXCHANGE_RESOURCE.data["Exchange"][dragMenu.currentIndex]
    if GameSaveManager.GetTowerDefensePacketValue(exchangeData.get("Key", 0))["Unlock"]:
        costLabel.visible = false
        exchangeButton.disabled = true
    else:
        exchangeButton.disabled = false
        costLabel.visible = true
        costLabel.text = str(int(exchangeData.get("CrystalNum", 0)))
    crystalNumLabel.text = str(int(GameSaveManager.GetKeyValue("CrystalNum")))

func PlayButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)

func Setup() -> void :
    for node in dragMenu.get_children():
        node.queue_free()
    var exchangeList = ONLINE_LEVEL_EXCHANGE_RESOURCE.data.get("Exchange", [])
    for exchangeData in exchangeList:
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(exchangeData.get("Key"))
        var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
        packet.onlyDraw = true
        packet.setMobileLayout = true
        dragMenu.add_child(packet)
        packet.Init(packetConfig)
    dragMenu.SetPos.call_deferred(0)

func BackButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    Close()

func AlmanacButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    var dialog = DialogManager.DialogCreate("Almanac")
    visible = false
    await dialog.close
    visible = true

func ExchangeButtonPressed() -> void :
    if GameSaveManager.GetKeyValue("CrystalNum") >= int(costLabel.text):
        var exchangeData = ONLINE_LEVEL_EXCHANGE_RESOURCE.data["Exchange"][dragMenu.currentIndex]
        var data = GameSaveManager.GetTowerDefensePacketValue(exchangeData.get("Key", 0))
        data["Unlock"] = true
        GameSaveManager.SetTowerDefensePacketValue(exchangeData.get("Key", 0), data)
        GameSaveManager.SetKeyValue("CrystalNum", GameSaveManager.GetKeyValue("CrystalNum") - int(costLabel.text))
        GameSaveManager.Save()
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]成功兑换[/font_size][/center]"
    else:
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]您的水晶不足[/font_size][/center]"

func ReadButtonPressed() -> void :
    readpaperTexture.visible = !readpaperTexture.visible

@warning_ignore("unused_parameter")
func ReadpaperTextureGuiInput(event: InputEvent) -> void :
    if Input.is_action_just_pressed("Press"):
        readpaperTexture.visible = false
