class_name LevelEditorMapEditor extends Control

static var instance: LevelEditorMapEditor

@onready var characterNode: Node2D = %CharacterNode
@onready var shovelButton: TextureButton = %ShovelButton
@onready var mapControl: TowerDefenseMapControl = %TowerDefenseMapControl

@export var levelConfig: TowerDefenseLevelConfig

var mapFeature: TowerDefenseBattleFeatureMap

var shovelShow: bool = false

func Init(_levelConfig: TowerDefenseLevelConfig) -> void :
    levelConfig = _levelConfig

func Save(isSave: bool = false) -> void :
    Release()
    if !is_instance_valid(levelConfig):
        return

    var vaseMode: bool = false
    match levelConfig.finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.VASE:
            vaseMode = true
    if (isSave && is_visible_in_tree()) || ( !isSave && !is_visible_in_tree()):
        levelConfig.preSpawnList.clear()
        if vaseMode:
            levelConfig.vaseManager.vaseList.clear()
        var characterSaveList: Array[TowerDefenseCharacter] = []
        if is_instance_valid(mapFeature):
            for x in range(1, mapFeature.config.gridNum.x + 1):
                for y in range(1, mapFeature.config.gridNum.y + 1):
                    var cell: TowerDefenseCellInstance = mapFeature.plantGrid[x][y]
                    var characterList = cell.GetCharacterListSave()
                    for character: TowerDefenseCharacter in characterList:
                        if characterSaveList.has(character):
                            continue
                        if vaseMode:
                            if character is TowerDefenseVase:
                                var vaseConfig = character.Export()
                                levelConfig.vaseManager.vaseList.append(vaseConfig)
                                characterSaveList.append(character)
                                continue
                        var preSpawnConfig: TowerDefenseLevelPreSpawnConfig = TowerDefenseLevelPreSpawnConfig.new()
                        preSpawnConfig.gridPos = Vector2(x, y)
                        preSpawnConfig.packetName = character.packet.saveKey
                        if character is TowerDefenseVase:
                            if is_instance_valid(character.packetConfig):
                                preSpawnConfig.characterOverride = TowerDefenseCharacterOverride.new()
                                preSpawnConfig.characterOverride.propertyChange = []
                                var propertyChangeConfig: TowerDefenseCharacterPropertyChangeConfig = TowerDefenseCharacterPropertyChangeConfig.new()
                                propertyChangeConfig.propertyName = "packetName"
                                propertyChangeConfig.value = character.packetConfig.saveKey
                                preSpawnConfig.characterOverride.propertyChange.append(propertyChangeConfig)
                        levelConfig.preSpawnList.append(preSpawnConfig)
                        characterSaveList.append(character)
        for character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
            if characterSaveList.has(character):
                continue
            var preSpawnConfig: TowerDefenseLevelPreSpawnConfig = TowerDefenseLevelPreSpawnConfig.new()
            preSpawnConfig.gridPos = character.gridPos
            preSpawnConfig.packetName = character.packet.saveKey
            levelConfig.preSpawnList.append(preSpawnConfig)
            characterSaveList.append(character)
        match levelConfig.finishMethod:
            TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE:
                levelConfig.vaseManager = null
        if ( !isSave && !is_visible_in_tree()):
            ClearCharacter()
    elif is_visible_in_tree():
        if is_instance_valid(mapFeature):
            for x in range(1, mapFeature.config.gridNum.x + 1):
                for y in range(1, mapFeature.config.gridNum.y + 1):
                    var cell: TowerDefenseCellInstance = mapFeature.plantGrid[x][y]
                    cell.Clear()
        for preSpawn: TowerDefenseLevelPreSpawnConfig in levelConfig.preSpawnList:
            var spawnCharacter = preSpawn.SpawnCharacter()
            if is_instance_valid(spawnCharacter):
                if is_instance_valid(preSpawn.characterOverride):
                    preSpawn.characterOverride.ExecuteCharacter(spawnCharacter)
        if is_instance_valid(levelConfig.vaseManager):
            for vaseConfig: TowerDefenseLevelVaseConfig in levelConfig.vaseManager.vaseList:
                var vasePacketConfig: TowerDefensePacketConfig
                match vaseConfig.type:
                    "Plant":
                        vasePacketConfig = TowerDefenseManager.GetPacketConfig("VasePlant")
                    "Zombie":
                        vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseZombie")
                    _:
                        vasePacketConfig = TowerDefenseManager.GetPacketConfig("VaseNormal")
                var vase = vasePacketConfig.Plant(vaseConfig.gridPos)
                if is_instance_valid(vase):
                    if vaseConfig.packetName != "":
                        vase.packetConfig = vaseConfig.GetPacket()

func Clear() -> void :
    levelConfig = null
    ClearCharacter()

func ClearCharacter() -> void :
    for character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
        if is_instance_valid(character):
            character.Destroy()

func _ready() -> void :
    instance = self
    mapFeature = TowerDefenseManager.GetMapFeature()
    if !is_instance_valid(mapFeature) && is_instance_valid(mapControl):
        mapFeature = TowerDefenseBattleFeatureMap.new()
        mapFeature.mapControl = mapControl
        mapControl.mapFeature = mapFeature
        for x in range(25):
            mapFeature.plantGrid.append([])
            for y in range(25):
                mapFeature.plantGrid[x].append(null)
        for y in range(25):
            mapFeature.lineUse.append(false)
        mapFeature.iceCapList.resize(23)
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.mapControl):
        if !is_instance_valid(mapFeature.packetPickControl):
            mapFeature.packetPickControl = PacketPickControl.new()
            mapFeature.packetPickControl.Init(mapFeature.mapControl, mapFeature)
            mapFeature.mapControl.add_child(mapFeature.packetPickControl)
        if !is_instance_valid(mapFeature.shovelManager):
            var shovel: ShovelManager = ShovelManager.new()
            shovel.mapShovelSprite = Sprite2D.new()
            shovel.mapShovelSprite.visible = false
            shovel.shovelConfig = TowerDefenseManager.GetShovel("ShovelDefault")
            if is_instance_valid(shovel.shovelConfig):
                shovel.mapShovelSprite.texture = shovel.shovelConfig.texture
            shovel.shovelButton = shovelButton
            shovel.Init(mapFeature.mapControl, mapFeature)
            mapFeature.shovelManager = shovel
            var shovelPickTool: ShovelPickTool = ShovelPickTool.new()
            shovelPickTool.Init(mapFeature.mapControl)
            shovelPickTool.SetShovelManager(shovel)
            mapFeature.packetPickControl.RegisterTool(shovelPickTool)

func _physics_process(delta: float) -> void :
    if is_instance_valid(mapFeature):
        mapFeature.Process(delta)

func ShovelButtonPressed() -> void :
    if !mapFeature:
        return
    if is_instance_valid(mapFeature.packetPickControl):
        mapFeature.packetPickControl.PacketPickRelease()
    if shovelButton.button_pressed:
        AudioManager.AudioPlay("Shovel", AudioManagerEnum.TYPE.SFX)
        if is_instance_valid(mapFeature.shovelManager):
            mapFeature.shovelManager.shovelPick = true
            mapFeature.shovelManager.mapShovelSprite.position = Vector2(-100, -100)
            mapFeature.shovelManager.mapShovelSprite.visible = true
    else:
        AudioManager.AudioPlay("ShovelDeny", AudioManagerEnum.TYPE.SFX)
        if is_instance_valid(mapFeature.shovelManager):
            mapFeature.shovelManager.shovelPick = false
            mapFeature.shovelManager.mapShovelSprite.visible = false

func Release() -> void :
    if !mapFeature:
        return
    if is_instance_valid(mapFeature.packetPickControl):
        mapFeature.packetPickControl.Release()
    shovelButton.button_pressed = false
