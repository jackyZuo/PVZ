class_name TowerDefenseInGameSeedBank extends Control

const TOWER_DEFENSE_IN_GAME_PACKET_SLOT = preload("res://Prefab/TowerDefense/GUI/InGame/Packet/TowerDefenseInGamePacketSlot.tscn")
const SEED_BANK_ZOMBIE = preload("uid://1styv80tn18a")
const SUN_BANK_ZOMBIE_MOBILE = preload("uid://bpdw8ty3ivc67")

@onready var pcControl: Control = %PCControl
@onready var pcSunLabel: Label = %SunLabel
@onready var pcSeedContainer: MarginContainer = %SeedContainer
@onready var pcItemContainer: HBoxContainer = %ItemContainer
@onready var pcPacketSlotContainer = %PacketSlotContainer
@onready var pcPacketContainer = %PacketContainer
@onready var pcSeedBankTexture: NinePatchRect = %SeedBankTexture
@onready var pcSunBankTexture: TextureRect = %SunBankTexture

@onready var mobileControl: Control = %MobileControl
@onready var mobileSunLabel: Label = %MobileSunLabel
@onready var mobileSeedContainer: MarginContainer = %MobileSeedContainer
@onready var mobileItemContainer: HBoxContainer = %MobileItemContainer
@onready var mobilePacketSlotContainer = %MobilePacketSlotContainer
@onready var mobilePacketContainer = %MobilePacketContainer
@onready var mobileSunBarTexture: TextureRect = %MobileSunBarTexture
@onready var mobileISeedContanin: MarginContainer = %MobileISeedContanin

var sunNumShow: float = 50.0:
    set(_sunNumShow):
        sunNumShow = _sunNumShow
        if sunLabel:
            sunLabel.text = str(int(round(sunNumShow)))

var packetNum: int = 0
var packetList: Array[TowerDefenseInGamePacketShow] = []
var packetNameSet: Dictionary = {}

var mobilePreset: bool = false

var sunLabel: Label
var itemContainer: HBoxContainer
var packetSlotContainer
var packetContainer
var seedContainer: MarginContainer
var sunBankTexture: TextureRect

func SetMobileMode(enabled: bool) -> void :
    if mobilePreset == enabled:
        return
    var target_container: Node = mobilePacketContainer if enabled else pcPacketContainer
    _transfer_packets(target_container)
    mobilePreset = enabled
    _apply_mode()
    GameSaveManager.SetConfigValue("MobilePreset", enabled)

func _apply_mode() -> void :
    if mobilePreset:
        pcControl.visible = false
        mobileControl.visible = true
        sunLabel = mobileSunLabel
        itemContainer = mobileItemContainer
        packetSlotContainer = mobilePacketSlotContainer
        packetContainer = mobilePacketContainer
        seedContainer = mobileSeedContainer
        sunBankTexture = mobileSunBarTexture
        pcSeedContainer.visible = false
        mobilePacketSlotContainer.visible = true
        pcPacketSlotContainer.visible = false
        custom_minimum_size.x = 0
    else:
        mobileControl.visible = false
        pcControl.visible = true
        sunLabel = pcSunLabel
        itemContainer = pcItemContainer
        packetSlotContainer = pcPacketSlotContainer
        packetContainer = pcPacketContainer
        seedContainer = pcSeedContainer
        sunBankTexture = pcSunBankTexture
        mobileSeedContainer.visible = false
        mobilePacketSlotContainer.visible = false
        pcPacketSlotContainer.visible = true
        custom_minimum_size.x = itemContainer.size.x
    _sync_packet_slots()
    seedContainer.visible = true
    sunNumShow = TowerDefenseManager.GetSun()
    itemContainer.visible = true

func _transfer_packets(target_container: Node) -> void :
    if packetContainer == target_container:
        return
    for child in packetContainer.get_children():
        if child is TowerDefenseInGamePacketShow:
            child.reparent(target_container)

func _sync_packet_slots() -> void :
    var slot_num: int = TowerDefenseManager.seedbankPacketMax
    _rebuild_packet_slots(pcPacketSlotContainer, slot_num, false)
    _rebuild_packet_slots(mobilePacketSlotContainer, slot_num, true)
    await get_tree().physics_frame
    if mobilePreset:
        custom_minimum_size.x = 0
    else:
        custom_minimum_size.x = seedContainer.size.x

func _rebuild_packet_slots(container: Node, slot_num: int, is_mobile: bool) -> void :
    for node in container.get_children():
        container.remove_child(node)
        node.queue_free()
    for id in slot_num:
        var slot: = TOWER_DEFENSE_IN_GAME_PACKET_SLOT.instantiate()
        container.add_child(slot)
        slot.SetMobileMode(is_mobile)

func _init_packet_slots(container: Node, slot_num: int, is_mobile: bool) -> void :
    for node in container.get_children():
        container.remove_child(node)
        node.queue_free()
    for id in slot_num:
        var slot: = TOWER_DEFENSE_IN_GAME_PACKET_SLOT.instantiate()
        container.add_child(slot)
        slot.SetMobileMode(is_mobile)
    container.visible = false

func _ready() -> void :
    BattleEventBus.uiSwitched.connect(SetMobileMode)

    var slotNum = TowerDefenseManager.GetPacketSlotNum()
    _init_packet_slots(pcPacketSlotContainer, slotNum, false)
    _init_packet_slots(mobilePacketSlotContainer, slotNum, true)
    mobilePreset = GameSaveManager.GetConfigValue("MobilePreset")
    packetList.clear()
    packetNameSet.clear()
    await get_tree().physics_frame
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        pcSeedBankTexture.texture = SEED_BANK_ZOMBIE
        mobileSunBarTexture.texture = SUN_BANK_ZOMBIE_MOBILE
    _apply_mode()

func UpdateDisplay() -> void :
    if is_instance_valid(seedContainer) and is_instance_valid(sunLabel) and !sunLabel.visible:
        sunLabel.visible = seedContainer.visible
    if is_instance_valid(sunBankTexture) and is_instance_valid(sunLabel) and !sunLabel.visible:
        sunLabel.visible = sunBankTexture.visible
    if CommandManager.debugSunMax:
        TowerDefenseManager.SetSun(100000)
    sunNumShow = TowerDefenseManager.GetSun()

func HasPacket(packetName: String) -> bool:
    return packetNameSet.has(packetName)

func CanAddPacket() -> bool:
    return packetNum < TowerDefenseManager.seedbankPacketMax

func GetPacketPos(id: int) -> Vector2:
    return packetSlotContainer.get_child(id).global_position

func AddPacket(_packetConfig: TowerDefensePacketConfig, isStart: bool = false) -> TowerDefenseInGamePacketShow:
    packetNum += 1
    var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    packetContainer.add_child(packet)
    packet.Init(_packetConfig)
    packet.onlyDraw = false
    packetNameSet[_packetConfig.saveKey] = true
    if !isStart:
        packet.pressed.connect(DeletePacket)
    else:
        packet.alive = true
        packet.start = true
        packet.pressed.connect(TowerDefenseManager.GetPacketPickControl().PickPacket)
        packet.StartInit()
    packetList.append(packet)
    return packet

func DeletePacket(_packet: TowerDefenseInGamePacketShow) -> void :
    var id: int = packetList.find(_packet)
    packetNameSet.erase(_packet.config.saveKey)
    TowerDefenseManager.GetPacketBankFeature().PacketAlive(_packet.config.saveKey)
    packetList.remove_at(id)
    _packet.queue_free()
    packetNum -= 1

func DeleteAllPacket() -> void :
    var clearList: Array[TowerDefenseInGamePacketShow] = []
    for packet: TowerDefenseInGamePacketShow in packetList:
        if packet.lock:
            clearList.append(packet)
            continue
        packetNameSet.erase(packet.config.saveKey)
        TowerDefenseManager.GetPacketBankFeature().PacketAlive(packet.config.saveKey)
        packet.queue_free()
    packetList = clearList
    packetNum = packetList.size()

func Prepare() -> void :
    for packet: Node in packetContainer.get_children():
        if packet is TowerDefenseInGamePacketShow:
            packet.alive = true
            packet.lock = false
            packet.onlyDraw = false
            packet.start = false
            packet.coldDownProgressBar.visible = false
            packet.pressed.connect(DeletePacket)
            if packet.pressed.is_connected(TowerDefenseManager.GetPacketPickControl().PickPacket):
                packet.pressed.disconnect(TowerDefenseManager.GetPacketPickControl().PickPacket)

func Ready() -> void :
    for packet: Node in packetContainer.get_children():
        if packet is TowerDefenseInGamePacketShow:
            packet.alive = false
            packet.lock = true
            packet.onlyDraw = true
            if packet.pressed.is_connected(DeletePacket):
                packet.pressed.disconnect(DeletePacket)

func Start() -> void :
    for packet: Node in packetContainer.get_children():
        if packet is TowerDefenseInGamePacketShow:
            packet.alive = true
            packet.lock = false
            packet.onlyDraw = false
            packet.start = true
            packet.StartInit()
            packet.pressed.connect(TowerDefenseManager.GetPacketPickControl().PickPacket)
            if packet.pressed.is_connected(DeletePacket):
                packet.pressed.disconnect(DeletePacket)

func StartFromProgress() -> void :
    for packet: Node in packetContainer.get_children():
        if packet is TowerDefenseInGamePacketShow:
            packet.start = true
            packet.onlyDraw = false
            if packet.pressed.is_connected(DeletePacket):
                packet.pressed.disconnect(DeletePacket)
            if !packet.pressed.is_connected(TowerDefenseManager.GetPacketPickControl().PickPacket):
                packet.pressed.connect(TowerDefenseManager.GetPacketPickControl().PickPacket)
            packet.VisibilityChanged()
