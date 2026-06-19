class_name LevelEditorInformationEditor extends Control

@onready var levelNumberSpinBox: SpinBox = %LevelNumberSpinBox
@onready var levelNameLineEdit: LineEdit = %LevelNameLineEdit
@onready var levelDescriptionTextEdit: TextEdit = %LevelDescriptionTextEdit
@onready var homeWorldOptionButton: OptionButton = %HomeWorldOptionButton
@onready var mapOptionButton: OptionButton = %MapOptionButton
@onready var bgmOptionButton: OptionButton = %BgmOptionButton
@onready var talkOptionButton: OptionButton = %TalkOptionButton
@onready var talkCheckBox: CheckBox = %TalkCheckBox
@onready var tutorialOptionButton: OptionButton = %TutorialOptionButton
@onready var tutorialCheckBox: CheckBox = %TutorialCheckBox
@onready var finishMethodOptionButton: OptionButton = %FinishMethodOptionButton
@onready var mowerUseCheckBox: CheckBox = %MowerUseCheckBox
@onready var vaseShuffleCheckBox: CheckBox = %VaseShuffleCheckBox
@onready var _IZMShuffleCheckBox: CheckBox = %IZMShuffleCheckBox
@onready var fogUseContainer: HBoxContainer = %FogUseContainer
@onready var fogBeginColumnContainer: HBoxContainer = %FogBeginColumnContainer
@onready var fogUseCheckBox: CheckBox = %FogUseCheckBox
@onready var fogBeginColumnSpinBox: SpinBox = %FogBeginColumnSpinBox
@onready var stormOpenContainer: HBoxContainer = %StormOpenContainer
@onready var stormOpenCheckBox: CheckBox = %StormOpenCheckBox


@onready var mapTexture: TextureRect = %MapTexture

@onready var vaseShuffleContainer: HBoxContainer = %VaseShuffleContainer
@onready var _IZMShuffleContainer: HBoxContainer = %IZMShuffleContainer

@export var levelConfig: TowerDefenseLevelConfig

static var instance: LevelEditorInformationEditor

var homeWorldTranslate: Dictionary = {
    GeneralEnum.HOMEWORLD.NOONE: "无", 
    GeneralEnum.HOMEWORLD.MORDEN: "现代"
}
var homeWorldDictionary: Dictionary = {
    "现代": GeneralEnum.HOMEWORLD.MORDEN, 
    "无": GeneralEnum.HOMEWORLD.NOONE
}

var finishMethodTranslate: Dictionary = {
    TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE: "波模式", 
    TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE: "罐子模式", 
    TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM: "我是僵尸模式"
}
var finishMethodDictionary: Dictionary = {
    "波模式": TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE, 
    "罐子模式": TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE, 
    "我是僵尸模式": TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM
}

var mapDictionary: Dictionary = {}
var bgmDictionary: Dictionary = {}
var talkDictionary: Dictionary = {}
var tutorialDictionary: Dictionary = {}

var graveStoneDictionary: Dictionary = {}

var isInit: bool = false

func Init(_levelConfig: TowerDefenseLevelConfig) -> void :
    isInit = true
    levelConfig = _levelConfig
    levelNumberSpinBox.value = levelConfig.levelNumber
    levelNameLineEdit.text = levelConfig.levelName
    levelDescriptionTextEdit.text = levelConfig.description
    stormOpenCheckBox.button_pressed = levelConfig.stormOpen
    mowerUseCheckBox.button_pressed = levelConfig.mowerUse
    homeWorldOptionButton.selected = FindOptionButtonId(homeWorldOptionButton, homeWorldTranslate[levelConfig.homeWorld])
    finishMethodOptionButton.selected = FindOptionButtonId(finishMethodOptionButton, finishMethodTranslate[levelConfig.finishMethod])
    FinishMethodOptionButtonItemSelected(finishMethodOptionButton.selected)
    var map: TowerDefenseMapConfig = ResourceManager.MAPS[levelConfig.map]
    mapOptionButton.selected = FindOptionButtonId(mapOptionButton, map.translate)
    MapOptionButtonItemSelected(mapOptionButton.selected)
    var bgm: TowerDefenseBackgroundMusicConfig = ResourceManager.BGMS[levelConfig.backgroundMusic]
    bgmOptionButton.selected = FindOptionButtonId(bgmOptionButton, bgm.translate)
    talkOptionButton.selected = FindOptionButtonId(talkOptionButton, levelConfig.talk)
    tutorialOptionButton.selected = FindOptionButtonId(tutorialOptionButton, levelConfig.tutorial)

    talkCheckBox.button_pressed = levelConfig.isCustomTalk
    tutorialCheckBox.button_pressed = levelConfig.isCustomTutorial

    if !is_instance_valid(levelConfig.fogManager):
        levelConfig.fogManager = TowerDefenseLevelFogManagerConfig.new()
    fogUseCheckBox.button_pressed = levelConfig.fogManager.open
    fogBeginColumnSpinBox.value = levelConfig.fogManager.beginColumn

    match levelConfig.finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            if !is_instance_valid(levelConfig.vaseManager):
                levelConfig.vaseManager = TowerDefenseLevelVaseManagerConfig.new()
            vaseShuffleCheckBox.button_pressed = levelConfig.vaseManager.shuffle
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            if !is_instance_valid(levelConfig._IZMManager):
                levelConfig._IZMManager = TowerDefenseLevelIZMManagerConfig.new()
            _IZMShuffleCheckBox.button_pressed = levelConfig._IZMManager.shuffle

    isInit = false

func Clear() -> void :
    levelConfig = null

func _ready() -> void :
    homeWorldOptionButton.get_popup().transparent = false
    mapOptionButton.get_popup().transparent = false
    bgmOptionButton.get_popup().transparent = false
    talkOptionButton.get_popup().transparent = false
    tutorialOptionButton.get_popup().transparent = false
    finishMethodOptionButton.get_popup().transparent = false
    instance = self
    for homeWorld in GeneralEnum.HOMEWORLD.values():
        homeWorldOptionButton.add_item(homeWorldTranslate[homeWorld])

    for finishMethod in finishMethodTranslate.keys():
        finishMethodOptionButton.add_item(finishMethodTranslate[finishMethod])

    for mapKey: String in ResourceManager.MAPS.keys():
        var map: TowerDefenseMapConfig = ResourceManager.MAPS[mapKey]
        mapOptionButton.add_item(map.translate)
        mapDictionary[map.translate] = mapKey

    for bgmKey in ResourceManager.BGMS.keys():
        var bgm: TowerDefenseBackgroundMusicConfig = ResourceManager.BGMS[bgmKey]
        bgmOptionButton.add_item(bgm.translate)
        bgmDictionary[bgm.translate] = bgmKey

    for talk in ResourceManager.TALKS.keys():
        talkOptionButton.add_item(talk)

    for tutorial in ResourceManager.TUTORIALS.keys():
        tutorialOptionButton.add_item(tutorial)

func SetMapTexture(texture: Texture2D) -> void :
    mapTexture.texture = texture
    mapTexture.scale = Vector2.ONE * 600.0 / texture.get_height() * 0.45

func FreshFinishMethod() -> void :
    vaseShuffleContainer.visible = false
    _IZMShuffleContainer.visible = false
    match levelConfig.finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE, TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            LevelEditorSeedbankEditor.instance.SetIZMMode(false)
            levelConfig.packetBank = "GeneralPlant"
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            _IZMShuffleContainer.visible = true
            if !is_instance_valid(levelConfig._IZMManager):
                levelConfig._IZMManager = TowerDefenseLevelIZMManagerConfig.new()
            _IZMShuffleCheckBox.button_pressed = levelConfig._IZMManager.shuffle
            LevelEditorSeedbankEditor.instance.SetIZMMode(true)
            levelConfig.packetBank = "GeneralZombie"
    match levelConfig.finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            vaseShuffleContainer.visible = true
            if !is_instance_valid(levelConfig.vaseManager):
                levelConfig.vaseManager = TowerDefenseLevelVaseManagerConfig.new()
            vaseShuffleCheckBox.button_pressed = levelConfig.vaseManager.shuffle
            var preSpawnList: Array[TowerDefenseLevelPreSpawnConfig] = []
            for preSpawn: TowerDefenseLevelPreSpawnConfig in levelConfig.preSpawnList:
                var packet = TowerDefenseManager.GetPacketConfig(preSpawn.packetName)
                if packet.characterConfig is TowerDefenseVaseConfig:
                    var vaseConfig: TowerDefenseLevelVaseConfig = TowerDefenseLevelVaseConfig.new()
                    vaseConfig.gridPos = preSpawn.gridPos
                    if is_instance_valid(preSpawn.characterOverride):
                        if preSpawn.characterOverride.propertyChange.size() > 0:
                            for propertyChangeConfig: TowerDefenseCharacterPropertyChangeConfig in preSpawn.characterOverride.propertyChange:
                                if propertyChangeConfig.propertyName == "packetName":
                                    vaseConfig.packetName = propertyChangeConfig.value
                                    break
                    match packet.saveKey:
                        "VasePlant":
                            vaseConfig.type = "Plant"
                        "VaseZombie":
                            vaseConfig.type = "Zombie"
                        _:
                            vaseConfig.type = "Normal"
                    levelConfig.vaseManager.vaseList.append(vaseConfig)
                    continue
                preSpawnList.append(preSpawn)
            levelConfig.preSpawnList = preSpawnList
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE, TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            match levelConfig.finishMethod:
                TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
                    levelConfig.packetBank = "GeneralPlant"
                TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
                    levelConfig.packetBank = "GeneralZombie"
            if is_instance_valid(levelConfig.vaseManager):
                for vaseConfig: TowerDefenseLevelVaseConfig in levelConfig.vaseManager.vaseList:
                    var preSpawnConfig: TowerDefenseLevelPreSpawnConfig = TowerDefenseLevelPreSpawnConfig.new()
                    preSpawnConfig.gridPos = vaseConfig.gridPos
                    match vaseConfig.type:
                        "Plant":
                            preSpawnConfig.packetName = "VasePlant"
                        "Zombie":
                            preSpawnConfig.packetName = "VaseZombie"
                        _:
                            preSpawnConfig.packetName = "VaseNormal"
                    if vaseConfig.packetName != "":
                        preSpawnConfig.characterOverride = TowerDefenseCharacterOverride.new()
                        var propertyChangeConfig: TowerDefenseCharacterPropertyChangeConfig = TowerDefenseCharacterPropertyChangeConfig.new()
                        propertyChangeConfig.propertyName = "packetName"
                        propertyChangeConfig.value = vaseConfig.packetName
                        preSpawnConfig.characterOverride.propertyChange.append(propertyChangeConfig)
                    levelConfig.preSpawnList.append(preSpawnConfig)
    match levelConfig.finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            levelConfig._IZMManager = null
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            levelConfig.vaseManager = null
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
            levelConfig._IZMManager = null
            levelConfig.vaseManager = null

func FindOptionButtonId(optionButton: OptionButton, key: String) -> int:
    for index in optionButton.item_count:
        if optionButton.get_item_text(index) == key:
            return optionButton.get_item_id(index)
    return -1

func LevelNumberSpinBoxValueChanged(value: float) -> void :
    levelConfig.levelNumber = int(value)

func LevelNameLineEditTextChanged(newText: String) -> void :
    levelConfig.levelName = newText

func LevelDescriptionLineEditTextChanged() -> void :
    levelConfig.description = levelDescriptionTextEdit.text

func HomeWorldOptionButtonItemSelected(index: int) -> void :
    var homeWorldName: String = homeWorldOptionButton.get_item_text(index)
    levelConfig.homeWorld = homeWorldDictionary[homeWorldName]

func MapOptionButtonItemSelected(index: int) -> void :
    if !isInit:
        levelConfig.canExport = false
    var mapName: String = mapOptionButton.get_item_text(index)
    var mapConfig: TowerDefenseMapConfig = ResourceManager.MAPS[mapDictionary[mapName]]
    if is_instance_valid(LevelEditorMapEditor.instance) && is_instance_valid(LevelEditorMapEditor.instance.mapFeature):
        LevelEditorMapEditor.instance.mapFeature.MapInit(mapConfig)
    LevelEditorWaveEditor.instance.MapChange(mapConfig)
    SetMapTexture(mapConfig.mapTexture)
    levelConfig.map = mapDictionary[mapName]
    fogBeginColumnSpinBox.max_value = mapConfig.gridNum.x

func BgmOptionButtonItemSelected(index: int) -> void :
    var bgmName: String = bgmOptionButton.get_item_text(index)
    levelConfig.backgroundMusic = bgmDictionary[bgmName]

func FinishMethodOptionButtonItemSelected(index: int) -> void :
    var finishMethodName: String = finishMethodOptionButton.get_item_text(index)
    levelConfig.finishMethod = finishMethodDictionary[finishMethodName]
    FreshFinishMethod()

func TalkOptionButtonItemSelected(index: int) -> void :
    var talkName: String = talkOptionButton.get_item_text(index)
    levelConfig.talk = talkName

func TutorialOptionButtonItemSelected(index: int) -> void :
    var tutorialName: String = tutorialOptionButton.get_item_text(index)
    levelConfig.tutorial = tutorialName

func TalkCheckBoxToggled(toggledOn: bool) -> void :
    talkOptionButton.disabled = toggledOn
    levelConfig.isCustomTalk = toggledOn
    if toggledOn:
        talkOptionButton.selected = -1
        levelConfig.talk = ""

func TutorialCheckBoxToggled(toggledOn: bool) -> void :
    tutorialOptionButton.disabled = toggledOn
    tutorialOptionButton.selected = -1
    if toggledOn:
        levelConfig.isCustomTutorial = toggledOn
        levelConfig.tutorial = ""

func MowerUseCheckBoxToggled(toggledOn: bool) -> void :
    if !isInit:
        levelConfig.canExport = false
    levelConfig.mowerUse = toggledOn

func StormOpenCheckBoxToggled(toggledOn: bool) -> void :
    if !isInit:
        levelConfig.canExport = false
    levelConfig.stormOpen = toggledOn

func FogUseCheckBoxToggled(toggledOn: bool) -> void :
    if !is_instance_valid(levelConfig.fogManager):
        levelConfig.fogManager = TowerDefenseLevelFogManagerConfig.new()
    levelConfig.fogManager.open = toggledOn
    fogBeginColumnContainer.visible = toggledOn

func FogBeginColumnSpinBoxValueChanged(value: float) -> void :
    if !is_instance_valid(levelConfig.fogManager):
        levelConfig.fogManager = TowerDefenseLevelFogManagerConfig.new()
    levelConfig.fogManager.beginColumn = int(value)

func VaseShuffleCheckBoxToggled(toggledOn: bool) -> void :
    if !isInit:
        levelConfig.canExport = false
    if !is_instance_valid(levelConfig.vaseManager):
        return
    levelConfig.vaseManager.shuffle = toggledOn

func IZMShuffleCheckBoxToggled(toggledOn: bool) -> void :
    if !isInit:
        levelConfig.canExport = false
    if !is_instance_valid(levelConfig._IZMManager):
        return
    levelConfig._IZMManager.shuffle = toggledOn
