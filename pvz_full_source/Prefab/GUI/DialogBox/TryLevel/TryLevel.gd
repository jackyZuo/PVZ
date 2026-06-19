extends DialogBoxBase

const TRY_LEVEL_RESOURCE = preload("res://Asset/Config/Level/TryLevelResource.json")
const DEBUFF_FINISH = preload("uid://dpm2kwh72n3p4")

@onready var dragMenu: DragMenu = %DragMenu
@onready var shopButton: TextureButton = %ShopButton
@onready var starExchangeButton: TextureButton = %StarExchangeButton

@onready var purpleButton: TextureButton = %PurpleButton
@onready var starButton: TextureButton = %StarButton
@onready var colourButton: TextureButton = %ColourButton

var currentGroup: String

func _ready() -> void :
    super._ready()
    if Global.enterTryLevelGroup == "":
        SelectPurple()
    else:
        match Global.enterTryLevelGroup:
            "Purple":
                SelectPurple()
            "Star":
                SelectStar()
            "Colour":
                SelectColour()
        Global.enterTryLevelGroup = ""

func PlayButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    var levelList = TRY_LEVEL_RESOURCE.data[currentGroup]
    var difficult: String = GameSaveManager.GetKeyValue("CurrentDifficult")
    if levelList[dragMenu.currentIndex]["Level"][difficult] != "":
        TowerDefenseManager.currentLevelConfig = load(levelList[dragMenu.currentIndex]["Level"][difficult])
    else:
        TowerDefenseManager.currentLevelConfig = load(levelList[dragMenu.currentIndex]["Level"]["Normal"])
    Global.enterLevelMode = "LevelChoose"
    Global.currentLevelChoose = "TryLevel"
    Global.enterTryLevelGroup = currentGroup
    SceneManager.ChangeScene("TowerDefense")

func SelectGroup(groupName: String) -> void :
    currentGroup = groupName
    for node in dragMenu.get_children():
        node.queue_free()
    var levelList = TRY_LEVEL_RESOURCE.data[groupName]
    for levelData in levelList:
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(levelData.get("Character"))
        var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
        packet.onlyDraw = true
        packet.setMobileLayout = true
        dragMenu.add_child(packet)
        packet.Init(packetConfig)

        var levelInformationData: Dictionary = GameSaveManager.GetLevelValue(levelData["SaveKey"])
        if CommandManager.debugOpenAllLevel || levelInformationData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0:
            var sprite = Sprite2D.new()
            sprite.texture = DEBUFF_FINISH
            sprite.scale = Vector2.ONE * 0.5
            sprite.position = Vector2(40, 25)
            packet.add_child(sprite)

    dragMenu.SetPos.call_deferred(0)

func SelectPurple() -> void :
    SelectGroup("Purple")
    purpleButton.button_pressed = true
    shopButton.visible = true
    starExchangeButton.visible = false

func SelectStar() -> void :
    SelectGroup("Star")
    starButton.button_pressed = true
    shopButton.visible = false
    starExchangeButton.visible = true

func SelectColour() -> void :
    SelectGroup("Colour")
    colourButton.button_pressed = true
    shopButton.visible = false
    starExchangeButton.visible = true

func BackButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    Close()

func ShopButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    DialogManager.DialogCreate("Shop")
    Close()

func StarExchangeButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    DialogManager.DialogCreate("StarExchange")
    Close()

func AlmanacButtonPressed() -> void :
    AudioManager.AudioPlay("ButtonPress", AudioManagerEnum.TYPE.SFX)
    var dialog = DialogManager.DialogCreate("Almanac")
    visible = false
    await dialog.close
    visible = true
