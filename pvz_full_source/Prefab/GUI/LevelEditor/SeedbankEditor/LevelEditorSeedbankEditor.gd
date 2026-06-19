class_name LevelEditorSeedbankEditor extends Control

@onready var plantColumnCheckBox: CheckBox = %PlantColumnCheckBox

@onready var sunContainer: VBoxContainer = %SunContainer
@onready var sunManagerContainer: VBoxContainer = %SunManagerContainer
@onready var conveyorContainer: VBoxContainer = %ConveyorContainer
@onready var packetColdDownStartContainer: HBoxContainer = %PacketColdDownStartContainer
@onready var packetColdDownUseContainer: HBoxContainer = %PacketColdDownUseContainer
@onready var rainModeContainer: VBoxContainer = %RainModeContainer

@onready var methodOptionButton: OptionButton = %MethodOptionButton
@onready var sunSpinBox: SpinBox = %SunSpinBox
@onready var sunUseCheckBox: CheckBox = %SunUseCheckBox
@onready var sunSpawnIntervalSpinBox: SpinBox = %SunSpawnIntervalSpinBox
@onready var sunSpawnNumSpinBox: SpinBox = %SunSpawnNumSpinBox
@onready var conveyorIntervalSpinBox: SpinBox = %ConveyorIntervalSpinBox
@onready var conveyorTypeOptionButton: OptionButton = %ConveyorTypeOptionButton
@onready var packetColdDownStartUseCheckBox: CheckBox = %PacketColdDownStartUseCheckBox
@onready var packetColdDownUseCheckBox: CheckBox = %PacketColdDownUseCheckBox

@onready var rainModeIntervalSpinBox: SpinBox = %RainModeIntervalSpinBox
@onready var rainModeAliveTimeSpinBox: SpinBox = %RainModeAliveTimeSpinBox
@onready var rainModeTypeOptionButton: OptionButton = %RainModeTypeOptionButton

static var instance: LevelEditorSeedbankEditor

@export var levelConfig: TowerDefenseLevelConfig

var isInit: bool = false

const methodTranslate: Dictionary = {
    TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.NOONE: "无", 
    TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE: "选卡模式", 
    TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET: "预选卡模式", 
    TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR: "传送带模式", 
    TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN: "种子雨模式"
}
const methodDictionary: Dictionary = {
    "无": TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.NOONE, 
    "选卡模式": TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE, 
    "预选卡模式": TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET, 
    "传送带模式": TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR, 
    "种子雨模式": TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN
}

var conveyorTypeTranslate: Dictionary = {
    "Default": "默认", 
    "Sun": "消耗阳光"
}
var conveyorTypeDictionary: Dictionary = {
    "默认": "Default", 
    "消耗阳光": "Sun"
}
var rainModeTypeTranslate: Dictionary = {
    "Default": "默认", 
    "Sun": "消耗阳光"
}
var rainModeTypeDictionary: Dictionary = {
    "默认": "Default", 
    "消耗阳光": "Sun"
}

func Init(_levelConfig: TowerDefenseLevelConfig) -> void :

    isInit = true

    Clear()


    levelConfig = _levelConfig

    plantColumnCheckBox.button_pressed = levelConfig.plantColumn

    methodOptionButton.selected = FindOptionButtonId(methodOptionButton, methodTranslate[levelConfig.packetBankMethod])
    MethodOptionButtonItemSelected(methodOptionButton.selected)

    if !is_instance_valid(levelConfig.conveyorData):
        levelConfig.conveyorData = TowerDefenseConveyorConfig.new()
    else:
        levelConfig.conveyorData = levelConfig.conveyorData.duplicate(true)
    conveyorIntervalSpinBox.value = levelConfig.conveyorData.interval
    conveyorTypeOptionButton.selected = FindOptionButtonId(conveyorTypeOptionButton, conveyorTypeTranslate[levelConfig.conveyorData.type])
    if levelConfig.packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
        ConveyorTypeOptionButtonItemSelected(conveyorTypeOptionButton.selected)

    if !is_instance_valid(levelConfig.rainData):
        levelConfig.rainData = TowerDefenseRainModeConfig.new()
    else:
        levelConfig.rainData = levelConfig.rainData.duplicate(true)
    rainModeIntervalSpinBox.value = levelConfig.rainData.interval
    rainModeAliveTimeSpinBox.value = levelConfig.rainData.aliveTime
    rainModeTypeOptionButton.selected = FindOptionButtonId(rainModeTypeOptionButton, rainModeTypeTranslate[levelConfig.rainData.type])
    if levelConfig.packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
        RainModeTypeOptionButtonItemSelected(rainModeTypeOptionButton.selected)

    if !is_instance_valid(levelConfig.sunManager):
        levelConfig.sunManager = TowerDefenseLevelSunManagerConfig.new()
    else:
        levelConfig.sunManager = levelConfig.sunManager.duplicate(true)
    sunSpinBox.value = levelConfig.sunManager.begin
    SunSpinBoxValueChanged(sunSpinBox.value)
    sunUseCheckBox.button_pressed = levelConfig.sunManager.open
    sunSpawnIntervalSpinBox.value = levelConfig.sunManager.spawnInterval
    sunSpawnNumSpinBox.value = levelConfig.sunManager.spawnNum
    packetColdDownStartUseCheckBox.button_pressed = levelConfig.packetColdDownStart
    packetColdDownUseCheckBox.button_pressed = levelConfig.packetColdDownUse

    match levelConfig.packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE, TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
            LevelEditorSeedBankChoose.instance.PacketListChoose(levelConfig.packetBankList)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
            for packet: TowerDefenseConveyorPacketConfig in levelConfig.conveyorData.packetList:
                LevelEditorSeedBankChoose.instance.PacketNameChoose(packet.name)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
            for packet: TowerDefenseRainModePacketConfig in levelConfig.rainData.packetList:
                LevelEditorSeedBankChoose.instance.PacketNameChoose(packet.name)
    isInit = false

func SetIZMMode(open: bool) -> void :
    if open:
        LevelEditorSeedbank.instance.seedBankTexture.texture = LevelEditorSeedbank.instance.SEED_BANK_ZOMBIE
    else:
        LevelEditorSeedbank.instance.seedBankTexture.texture = LevelEditorSeedbank.instance.SEED_BANK

func Save() -> void :
    if !is_instance_valid(levelConfig):
        return

    levelConfig.plantColumn = plantColumnCheckBox.button_pressed

    levelConfig.conveyorData.interval = conveyorIntervalSpinBox.value

    levelConfig.rainData.interval = rainModeIntervalSpinBox.value
    levelConfig.rainData.aliveTime = rainModeAliveTimeSpinBox.value

    levelConfig.sunManager.begin = int(sunSpinBox.value)
    levelConfig.sunManager.open = sunUseCheckBox.button_pressed
    levelConfig.sunManager.spawnInterval = sunSpawnIntervalSpinBox.value
    levelConfig.sunManager.spawnNum = int(sunSpawnNumSpinBox.value)

    levelConfig.packetColdDownStart = packetColdDownStartUseCheckBox.button_pressed
    levelConfig.packetColdDownUse = packetColdDownUseCheckBox.button_pressed

    match levelConfig.packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE, TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
            levelConfig.packetBankList.clear()
            for packet: TowerDefenseInGamePacketShow in LevelEditorSeedbank.instance.packetList:
                var config: TowerDefenseLevelPacketConfig = TowerDefenseLevelPacketConfig.new()
                config.packetName = packet.config.saveKey
                levelConfig.packetBankList.append(config)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
            levelConfig.conveyorData.packetList.clear()
            for packet: TowerDefenseInGamePacketShow in LevelEditorSeedbank.instance.packetList:
                var config: TowerDefenseConveyorPacketConfig = TowerDefenseConveyorPacketConfig.new()
                config.name = packet.config.saveKey
                levelConfig.conveyorData.packetList.append(config)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
            levelConfig.rainData.packetList.clear()
            for packet: TowerDefenseInGamePacketShow in LevelEditorSeedbank.instance.packetList:
                var config: TowerDefenseRainModePacketConfig = TowerDefenseRainModePacketConfig.new()
                config.name = packet.config.saveKey
                levelConfig.rainData.packetList.append(config)


func Clear() -> void :
    LevelEditorSeedbank.instance.Clear()
    levelConfig = null

func _ready() -> void :
    methodOptionButton.get_popup().transparent = false
    conveyorTypeOptionButton.get_popup().transparent = false
    rainModeTypeOptionButton.get_popup().transparent = false

    instance = self

    for method in TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.values():
        methodOptionButton.add_item(methodTranslate[method])

    for conveyorType in conveyorTypeTranslate.keys():
        conveyorTypeOptionButton.add_item(conveyorTypeTranslate[conveyorType])

    for rainModeType in rainModeTypeTranslate.keys():
        rainModeTypeOptionButton.add_item(rainModeTypeTranslate[rainModeType])

func FindOptionButtonId(optionButton: OptionButton, key: String) -> int:
    for index in optionButton.item_count:
        if optionButton.get_item_text(index) == key:
            return optionButton.get_item_id(index)
    return -1

func MethodOptionButtonItemSelected(index: int) -> void :
    if !isInit:
        levelConfig.canExport = false
    var methodName: String = methodOptionButton.get_item_text(index)
    levelConfig.packetBankMethod = methodDictionary[methodName]
    LevelEditorSeedbank.instance.seedContanin.visible = false
    LevelEditorSeedbank.instance.conveyor.visible = false
    LevelEditorSeedbank.instance.packetContainer.visible = false
    packetColdDownStartContainer.visible = false
    packetColdDownUseContainer.visible = false
    sunContainer.visible = false
    conveyorContainer.visible = false
    rainModeContainer.visible = false
    match levelConfig.packetBankMethod:
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.NOONE:
            packetColdDownStartContainer.visible = true
            packetColdDownUseContainer.visible = true
            sunContainer.visible = true
            LevelEditorSeedBankChoose.instance.visible = false
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CHOOSE, TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.PRESET:
            LevelEditorSeedbank.instance.seedContanin.visible = true
            LevelEditorSeedbank.instance.packetContainer.visible = true
            packetColdDownStartContainer.visible = true
            packetColdDownUseContainer.visible = true
            sunContainer.visible = true
            LevelEditorSeedBankChoose.instance.visible = true
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.CONVEYOR:
            sunUseCheckBox.button_pressed = false
            LevelEditorSeedbank.instance.conveyor.visible = true
            LevelEditorSeedbank.instance.packetContainer.visible = true
            conveyorContainer.visible = true
            LevelEditorSeedBankChoose.instance.visible = true
            if !is_instance_valid(levelConfig.conveyorData):
                levelConfig.conveyorData = TowerDefenseConveyorConfig.new()
            conveyorTypeOptionButton.selected = FindOptionButtonId(conveyorTypeOptionButton, conveyorTypeTranslate[levelConfig.conveyorData.type])
            ConveyorTypeOptionButtonItemSelected(conveyorTypeOptionButton.selected)
        TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
            sunUseCheckBox.button_pressed = false
            LevelEditorSeedbank.instance.seedContanin.visible = true
            LevelEditorSeedbank.instance.packetContainer.visible = true
            rainModeContainer.visible = true
            LevelEditorSeedBankChoose.instance.visible = true
            if !is_instance_valid(levelConfig.rainData):
                levelConfig.rainData = TowerDefenseRainModeConfig.new()
            rainModeTypeOptionButton.selected = FindOptionButtonId(rainModeTypeOptionButton, rainModeTypeTranslate[levelConfig.rainData.type])
            RainModeTypeOptionButtonItemSelected(rainModeTypeOptionButton.selected)

func SunUseCheckBoxToggled(toggledOn: bool) -> void :
    if !isInit:
        levelConfig.canExport = false
    sunManagerContainer.visible = toggledOn

func SunSpinBoxValueChanged(value: float) -> void :
    if !isInit:
        levelConfig.canExport = false
    LevelEditorSeedbank.instance.sunLabel.text = str(int(value))
    LevelEditorSeedbank.instance.conveyorSunLabel.text = str(int(value))

func PacketColdDownStartUseCheckBoxPressed() -> void :
    if !isInit:
        levelConfig.canExport = false

func PacketColdDownUseCheckBoxPressed() -> void :
    if !isInit:
        levelConfig.canExport = false

@warning_ignore("unused_parameter")
func SunSpawnIntervalSpinBoxValueChanged(value: float) -> void :
    if !isInit:
        levelConfig.canExport = false

@warning_ignore("unused_parameter")
func SunSpawnNumSpinBoxValueChanged(value: float) -> void :
    if !isInit:
        levelConfig.canExport = false

@warning_ignore("unused_parameter")
func RainModeIntervalSpinBoxValueChanged(value: float) -> void :
    if !isInit:
        levelConfig.canExport = false

@warning_ignore("unused_parameter")
func RainModeAliveTimeSpinBoxValueChanged(value: float) -> void :
    if !isInit:
        levelConfig.canExport = false

@warning_ignore("unused_parameter")
func PlantColumnCheckBoxToggled(toggled_on: bool) -> void :
    if !isInit:
        levelConfig.canExport = false

func ConveyorTypeOptionButtonItemSelected(index: int) -> void :
    var conveyorType: String = conveyorTypeOptionButton.get_item_text(index)
    levelConfig.conveyorData.type = conveyorTypeDictionary[conveyorType]
    if levelConfig.conveyorData.type == "Sun":
        LevelEditorSeedbank.instance.conveyorBeltRectPC.texture = LevelEditorSeedbank.instance.CONVEYOR_BELT_SUN_BACKDROP
        LevelEditorSeedbank.instance.belt.texture = LevelEditorSeedbank.instance.CONVEYOR_BELT_SUN
        LevelEditorSeedbank.instance.conveyorSunBankTexture.visible = true
        sunContainer.visible = true
    else:
        LevelEditorSeedbank.instance.conveyorBeltRectPC.texture = LevelEditorSeedbank.instance.CONVEYOR_BELT_BACKDROP
        LevelEditorSeedbank.instance.belt.texture = LevelEditorSeedbank.instance.CONVEYOR_BELT
        LevelEditorSeedbank.instance.conveyorSunBankTexture.visible = false
        sunContainer.visible = false

func RainModeTypeOptionButtonItemSelected(index: int) -> void :
    var rainModeType: String = rainModeTypeOptionButton.get_item_text(index)
    levelConfig.rainData.type = rainModeTypeDictionary[rainModeType]
    sunContainer.visible = levelConfig.rainData.type == "Sun"
