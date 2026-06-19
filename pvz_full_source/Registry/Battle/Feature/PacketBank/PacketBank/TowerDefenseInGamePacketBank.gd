class_name TowerDefenseInGamePacketBank extends Control

const PACKET_BANK_ZOMBIE_PANEL = preload("uid://cpd1x4qxqksuh")

@onready var translate: Control = %Translate

@onready var packetBankPanelTexture: NinePatchRect = %PacketBankPanelTexture

@onready var packetBankScroll: ScrollContainer = %PacketBankScroll
@onready var packetBankMargin: MarginContainer = %PacketBankMargin

@onready var packetContainer: GridContainer = %PacketContainer
@onready var animeNode: Control = %AnimeNode

@onready var cardSort: TextureRect = %CardSort

@onready var packetBankAnimationPlayer: AnimationPlayer = %PacketBankAnimationPlayer

@onready var cardZombie: Control = %CardZombie
@onready var cardItem: Control = %CardItem
@onready var cardGraveStone: Control = %CardGraveStone

var seedBank: TowerDefenseInGameSeedBank

var mobilePreset: bool = false

var _packetPool: Array[TowerDefenseInGamePacketShow] = []

var packetBankFeature

func SetMobileMode(enabled: bool) -> void :
    if mobilePreset == enabled:
        return
    var is_hidden: bool = !visible || translate.position.y >= 500.0
    if is_instance_valid(packetBankAnimationPlayer):
        packetBankAnimationPlayer.stop()
    mobilePreset = enabled
    _apply_mode()
    _apply_display_position(is_hidden)

func _apply_display_position(is_hidden: bool = false) -> void :
    if mobilePreset:
        if is_hidden:
            translate.position = Vector2(210.0, 600.0)
        else:
            translate.position = Vector2(210.0, 72.0)
    else:
        if is_hidden:
            translate.position = Vector2(0.0, 600.0)
        else:
            translate.position = Vector2(0.0, 86.0)

func _apply_mode() -> void :
    if mobilePreset:
        packetBankScroll.size = Vector2(590.0, 422.0)
        packetBankScroll.position = Vector2(10.0, 34.0)
        packetBankMargin.add_theme_constant_override("margin_left", 48)
        packetBankMargin.add_theme_constant_override("margin_top", 30)
        packetBankMargin.add_theme_constant_override("margin_right", 48)
        packetBankMargin.add_theme_constant_override("margin_bottom", 30)
        packetContainer.columns = 6
        packetContainer.add_theme_constant_override("h_separation", 98)
        packetContainer.add_theme_constant_override("v_separation", 62)
    else:
        packetBankScroll.position = Vector2(17.0, 34.0)
        packetBankScroll.size = Vector2(580.0, 422.0)
        packetBankMargin.add_theme_constant_override("margin_left", 25)
        packetBankMargin.add_theme_constant_override("margin_top", 32)
        packetBankMargin.add_theme_constant_override("margin_right", 25)
        packetBankMargin.add_theme_constant_override("margin_bottom", 38)
        packetContainer.columns = 11
        packetContainer.add_theme_constant_override("h_separation", 52)
        packetContainer.add_theme_constant_override("v_separation", 70)

func _ready() -> void :
    BattleEventBus.uiSwitched.connect(SetMobileMode)
    mobilePreset = GameSaveManager.GetConfigValue("MobilePreset")
    _apply_mode()
    if mobilePreset:
        translate.position = Vector2(210.0, 600.0)
    else:
        translate.position = Vector2(0.0, 600.0)

    var open = CommandManager.debugPacketOpenAll || \
Global.enterLevelMode == "OnlineLevel" || \
Global.enterLevelMode == "LoadLevel" || \
Global.enterLevelMode == "DiyLevel"

    cardZombie.visible = open
    cardItem.visible = open
    cardGraveStone.visible = open
    await get_tree().physics_frame
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        cardSort.visible = false
        packetBankPanelTexture.texture = PACKET_BANK_ZOMBIE_PANEL

func _notification(what: int) -> void :
    if what == NOTIFICATION_PREDELETE:
        for packet in _packetPool:
            if is_instance_valid(packet):
                packet.free()
        _packetPool.clear()

func GetCameraPos() -> Vector2:
    return get_viewport().get_camera_2d().global_position

func CreateAnime(config: TowerDefensePacketConfig, pos: Vector2) -> void :
    var cameraPos: Vector2 = Global.get_viewport().get_camera_2d().global_position
    var animePacket: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    animeNode.add_child(animePacket)
    animePacket.Init(config)
    animePacket.onlyDraw = true
    animePacket.global_position = pos - cameraPos

    var tween = animePacket.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUART)
    tween.tween_property(animePacket, "global_position", seedBank.GetPacketPos(seedBank.packetNum), 0.5)
    var packetConfig: TowerDefensePacketConfig = config.duplicate(true)
    var packet: TowerDefenseInGamePacketShow = seedBank.AddPacket(packetConfig, TowerDefenseManager.IsGameRunning())
    packet.visible = false
    await tween.finished
    if is_instance_valid(packet):
        packet.visible = true
        animePacket.queue_free()

func ClearAnimeNode() -> void :
    for node in animeNode.get_children():
        node.queue_free()

func ClearPackets() -> void :
    for packet in packetContainer.get_children():
        _ReturnPacketToPool(packet)

func _ReturnPacketToPool(packet: TowerDefenseInGamePacketShow) -> void :
    if packet.pressed.is_connected(packetBankFeature.PacketChoose):
        packet.pressed.disconnect(packetBankFeature.PacketChoose)
    if packet.loveChange.is_connected(packetBankFeature.LoveChange):
        packet.loveChange.disconnect(packetBankFeature.LoveChange)
    packet.ResetForPool()
    packetContainer.remove_child(packet)
    if _packetPool.size() < 200:
        _packetPool.append(packet)
    else:
        packet.queue_free()

func GetPacketFromPool() -> TowerDefenseInGamePacketShow:
    if _packetPool.size() > 0:
        return _packetPool.pop_back()
    return TowerDefenseManager.CreatePacketShow()

func AddPacketToContainer(packet: TowerDefenseInGamePacketShow) -> void :
    packetContainer.add_child(packet)
