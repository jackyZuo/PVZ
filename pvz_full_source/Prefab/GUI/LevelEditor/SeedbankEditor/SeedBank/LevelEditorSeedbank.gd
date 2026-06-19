class_name LevelEditorSeedbank extends Control

const SEED_BANK_ZOMBIE = preload("uid://1styv80tn18a")
const SEED_BANK = preload("uid://c2ihkj4xv50hg")
const CONVEYOR_BELT_SUN = preload("uid://i6rwl358wldw")
const CONVEYOR_BELT_SUN_BACKDROP = preload("uid://6h0njlvpp86")
const CONVEYOR_BELT = preload("uid://dbyiqyhraff1b")
const CONVEYOR_BELT_BACKDROP = preload("uid://ddglfhcpxg451")

@onready var posMask: Control = %PosMask

@onready var sunLabel: Label = %SunLabel
@onready var seedContanin: MarginContainer = %SeedContanin
@onready var conveyor: Control = %Conveyor

@onready var packetSlotContainer: HBoxContainer = %PacketSlotContainer
@onready var packetContainer: HBoxContainer = %PacketContainer

@onready var seedBankTexture: NinePatchRect = %SeedBankTexture

@onready var conveyorBeltRectPC: NinePatchRect = %ConveyorBeltRectPC
@onready var belt: TextureRect = %Belt
@onready var conveyorSunBankTexture: TextureRect = %ConveyorSunBankTexture
@onready var conveyorSunLabel: Label = %ConveyorSunLabel


static var instance: LevelEditorSeedbank

var packetNum: int = 0

var packetList: Array[TowerDefenseInGamePacketShow] = []

func _ready() -> void :
    instance = self

func Clear() -> void :
    for packet in packetList:
        packet.queue_free()
    packetList.clear()
    packetNum = 0

func CanAddPacket() -> bool:
    return packetNum < 16

func GetPacketPos(id: int) -> Vector2:
    return posMask.global_position + Vector2(51 * id, 0)

func AddPacket(_packetConfig) -> TowerDefenseInGamePacketShow:
    packetNum += 1
    var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    packet.setPcLayout = true
    packetContainer.add_child(packet)
    packet.thumbnailMode = true
    packet.Init(_packetConfig)
    packet.onlyDraw = false
    packet.pressed.connect(DeletePacket)
    packetList.append(packet)
    return packet

func DeletePacket(_packet: TowerDefenseInGamePacketShow) -> void :
    LevelEditorSeedbankEditor.instance.levelConfig.canExport = false
    var id: int = packetList.find(_packet)
    packetList.remove_at(id)
    _packet.queue_free()
    packetNum -= 1
