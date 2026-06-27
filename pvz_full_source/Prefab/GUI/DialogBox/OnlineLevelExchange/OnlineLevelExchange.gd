extends DialogBoxBase

const ONLINE_LEVEL_EXCHANGE_RESOURCE = preload("res://Asset/Config/OnlineLevelExchange/OnlineLevelExchangeResource.json")
const TEXTURE_PLANT = preload("res://Asset/Texture/GUI/OnlineLevelExchange/OnlineLevelExchangeSelectPlant.png")
const TEXTURE_CUSTOM = preload("res://Asset/Texture/GUI/OnlineLevelExchange/OnlineLevelExchangeSelectCustom.png")

@onready var dragMenu: DragMenu = %DragMenu
@onready var costLabel: Label = %CostLabel
@onready var exchangeButton: TextureButton = %ExchangeButton
@onready var crystalNumLabel: Label = %CrystalNumLabel
@onready var readpaperTexture: TextureRect = %ReadpaperTexture
@onready var switchModeButton: TextureButton = %SwitchModeButton
@onready var readButton: TextureButton = %ReadButton

var currentGroup: String
var currentMode: String = "Plant"
var filteredExchangeList: Array = []

func _ready() -> void :
    super._ready()
    Setup()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :

    var exchangeData = filteredExchangeList[dragMenu.currentIndex]
    match exchangeData.get("Type", "Packet"):
        "Packet":
            if GameSaveManager.GetTowerDefensePacketValue(exchangeData.get("Key", 0))["Unlock"]:
                costLabel.visible = false
                exchangeButton.disabled = true
            else:
                exchangeButton.disabled = false
                costLabel.visible = true
                costLabel.text = str(int(exchangeData.get("CrystalNum", 0)))
        "Feature":
            if GameSaveManager.GetFeatureValue(exchangeData.get("Key", 0)):
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
    filteredExchangeList.clear()
    var targetType: String = "Packet" if currentMode == "Plant" else "Feature"
    for exchangeData in exchangeList:
        if exchangeData.get("Type", "Packet") != targetType:
            continue
        filteredExchangeList.append(exchangeData)
        match exchangeData.get("Type", "Packet"):
            "Packet":
                var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(exchangeData.get("Key"))
                var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
                packet.onlyDraw = true
                packet.setMobileLayout = true
                dragMenu.add_child(packet)
                packet.Init(packetConfig)
            "Feature":
                var wrapper: Control = Control.new()
                dragMenu.add_child(wrapper)
                var icon: TextureRect = TextureRect.new()
                icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                icon.texture = load(exchangeData.get("Texture"))
                icon.custom_minimum_size = Vector2(80, 80)
                icon.position = Vector2(-40, -40)
                wrapper.add_child(icon)
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

func fade(node: Control, fadeIn: bool) -> Tween:
    var tween = create_tween()
    if fadeIn:
        node.modulate.a = 0.0
        node.visible = true
        tween.tween_property(node, "modulate:a", 1.0, 0.2)
    else:
        tween.tween_property(node, "modulate:a", 0.0, 0.2)
        await tween.finished
        node.visible = false
        node.modulate.a = 1.0
    return tween

func SwitchModeButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    await fade(switchModeButton, false)
    currentMode = "Custom" if currentMode == "Plant" else "Plant"
    switchModeButton.texture_normal = TEXTURE_CUSTOM if currentMode == "Custom" else TEXTURE_PLANT
    Setup()
    fade(switchModeButton, true)

func ExchangeButtonPressed() -> void :
    if GameSaveManager.GetKeyValue("CrystalNum") >= int(costLabel.text):
        var exchangeData = filteredExchangeList[dragMenu.currentIndex]
        match exchangeData.get("Type", "Packet"):
            "Packet":
                var data = GameSaveManager.GetTowerDefensePacketValue(exchangeData.get("Key", 0))
                data["Unlock"] = true
                GameSaveManager.SetTowerDefensePacketValue(exchangeData.get("Key", 0), data)
            "Feature":
                GameSaveManager.SetFeatureValue(exchangeData.get("Key", 0), true)
        GameSaveManager.SetKeyValue("CrystalNum", GameSaveManager.GetKeyValue("CrystalNum") - int(costLabel.text))
        GameSaveManager.Save()
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]成功兑换[/font_size][/center]"
    else:
        var tipsDialog = DialogManager.DialogCreate("DialogBoxTips")
        tipsDialog.text = "[center][font_size=24]您的水晶不足[/font_size][/center]"

func ReadButtonPressed() -> void :
    fade(readpaperTexture, !readpaperTexture.visible)

@warning_ignore("unused_parameter")
func ReadpaperTextureGuiInput(event: InputEvent) -> void :
    if Input.is_action_just_pressed("Press") and readpaperTexture.visible:
        ReadButtonPressed()
