class_name LevelEditorPacketBank extends Control

@onready var packetBankScroll: ScrollContainer = %PacketBankScroll
@onready var packetBankMargin: MarginContainer = %PacketBankMargin

@onready var packetContainer: GridContainer = %PacketContainer
@export var data: TowerDefensePacketBankData

static var instance: LevelEditorPacketBank

var mapFeature: TowerDefenseBattleFeatureMap

var packetList: Array[TowerDefenseInGamePacketShow] = []

var currentCategory: String = ""
var currentIndex: int = -1
var _categoryGeneration: int = 0

func Init(_data: TowerDefensePacketBankData) -> void :
    data = _data
    PacketClear()
    CategoryChoose("White")


func _ready() -> void :
    instance = self
    data = TowerDefenseManager.GetPacketBankData("Total")
    if data:
        Init(data)

func PacketChoose(packet: TowerDefenseInGamePacketShow) -> void :
    var _mapFeature: TowerDefenseBattleFeatureMap = mapFeature
    if !is_instance_valid(_mapFeature) && is_instance_valid(LevelEditorMapEditor.instance):
        _mapFeature = LevelEditorMapEditor.instance.mapFeature
        mapFeature = _mapFeature
    if !_mapFeature || !is_instance_valid(_mapFeature.packetPickControl):
        return
    _mapFeature.packetPickControl.PickPacket(packet)
    var nextIndex: int = packetList.find(packet)
    if nextIndex != currentIndex:
        if currentIndex != -1:
            var prePacket: TowerDefenseInGamePacketShow = packetList[currentIndex]
            prePacket.Reset()

        currentIndex = nextIndex

func PacketAlive(packetName: String) -> void :
    for packet: TowerDefenseInGamePacketShow in packetList:
        if packet.config.saveKey == packetName:
            packet.alive = true
            return

func PacketClear() -> void :
    for packet in packetContainer.get_children():
        packet.queue_free()
    packetList = []
    currentIndex = 0

func CategoryChoose(_category: String, reFresh: bool = false) -> void :
    if currentCategory == _category && !reFresh:
        return
    currentCategory = _category
    PacketClear()
    if !data.category.has(_category):
        return
    _categoryGeneration += 1
    var currentGeneration: int = _categoryGeneration
    var getConfigList: Array = data.category[_category]
    var configList: Array = []
    var unLoveList: Array = []
    for configName: String in getConfigList:
        var packetData: Dictionary = GameSaveManager.GetTowerDefensePacketValue(configName)
        if packetData.get_or_add("Love", false):
            configList.append(configName)
        else:
            unLoveList.append(configName)
    configList.append_array(unLoveList)

    var batchCount: int = 0
    for configName: String in configList:
        if _categoryGeneration != currentGeneration:
            return
        var config = TowerDefenseManager.GetPacketConfig(configName)
        var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
        packet.setPcLayout = true
        packetContainer.add_child(packet)
        packet.thumbnailMode = true
        packet.Init(config)
        packet.showLove = true
        packet.loveChange.connect(LoveChange)
        packet.pressed.connect(PacketChoose)
        packetList.append(packet)
        batchCount += 1
        if batchCount >= 8:
            batchCount = 0
            await get_tree().process_frame
            if _categoryGeneration != currentGeneration:
                return

    if is_instance_valid(LevelEditorMapEditor.instance):
        LevelEditorMapEditor.instance.Release()

@warning_ignore("unused_parameter")
func LoveChange(packet: TowerDefenseInGamePacketShow) -> void :
    CategoryChoose(currentCategory, true)
