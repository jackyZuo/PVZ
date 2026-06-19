class_name TowerDefenseBattleFeatureMap extends TowerDefenseBattleFeature

const TOWER_DEFENSE_MAP_CONTROL = preload("uid://q2eo6wgcbefw")
const TOWER_DEFENSE_ICE_CAP = preload("uid://b7eq2mfpja1dy")
const GRID_MAX_SIZE = 27

var mapControl: TowerDefenseMapControl
var mapConfig: TowerDefenseMapConfig

var config: TowerDefenseMapConfig
var firstConfig: TowerDefenseMapConfig
var changeConfig: TowerDefenseMapConfig
var isSwich: bool = false
var switchTimer: float = 100.0
var switchTween: Tween
var strigeRow: int = -1
var lineUse: Array[bool]
var plantGrid: Array[Array]
var iceCapList: Array = []
var currentMap: TowerDefenseMap = null
var nextMap: TowerDefenseMap = null
var isChange: bool = false
var currentGradientPos: float = 0.0
var currentGradient: GradientTexture1D
var rect: Rect2
var groundRect: Rect2
var isPlantColumn: bool = false
var shovelManager: ShovelManager
var gloveManager: GloveManager
var packetPickControl: PacketPickControl

func SaveFeature() -> Dictionary:
    print("[Save] 保存Feature[Map]...")
    var gridData: Array = []
    for x: int in plantGrid.size():
        var colData: Array = []
        for y: int in plantGrid[x].size():
            var cellInstance: TowerDefenseCellInstance = plantGrid[x][y]
            if is_instance_valid(cellInstance):
                colData.append(_SaveCell(cellInstance))
            else:
                colData.append(null)
        gridData.append(colData)
    var mowerData: Array = []
    var mowerFeature: TowerDefenseBattleFeatureMower = TowerDefenseManager.GetMowerFeature()
    if mowerFeature:
        for character: TowerDefenseCharacter in mowerFeature.mowerLine:
            if is_instance_valid(character):
                mowerData.append(character.name.validate_node_name())
            else:
                mowerData.append("")
    var brainData: Array = []
    var brainFeature: TowerDefenseBattleFeatureBrain = TowerDefenseManager.GetBrainFeature()
    if brainFeature:
        for character: TowerDefenseCharacter in brainFeature.brainLine:
            if is_instance_valid(character):
                brainData.append(character.name.validate_node_name())
            else:
                brainData.append("")
    var targetZombieData: Array = []
    if mowerFeature:
        for character: TowerDefenseCharacter in mowerFeature.targetZombieLine:
            if is_instance_valid(character):
                targetZombieData.append(character.name.validate_node_name())
            else:
                targetZombieData.append("")
    var changeConfigPath: String = ""
    if is_instance_valid(changeConfig):
        changeConfigPath = changeConfig.resource_path
    var result: Dictionary = {
        "isSwich": isSwich, 
        "switchTimer": switchTimer, 
        "strigeRow": strigeRow, 
        "isPlantColumn": isPlantColumn, 
        "isChange": isChange, 
        "currentGradientPos": currentGradientPos, 
        "lineUse": lineUse.duplicate(true), 
        "plantGrid": gridData, 
        "mowerLine": mowerData, 
        "brainLine": brainData, 
        "targetZombieLine": targetZombieData, 
        "mowerHasRun": mowerFeature.mowerHasRun if mowerFeature else false, 
        "changeConfigPath": changeConfigPath, 
    }
    print("[Save] Feature[Map]保存完成: gridData=%d行, mowerLine=%d, brainLine=%d, isSwich=%s, isChange=%s" % [gridData.size(), mowerData.size(), brainData.size(), isSwich, isChange])
    return result

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    print("[Load] 加载Feature[Map]... (数据项: %d)" % _data.size())
    isSwich = _data.get("isSwich", false)
    switchTimer = _data.get("switchTimer", 100.0)
    strigeRow = _data.get("strigeRow", -1)
    isPlantColumn = _data.get("isPlantColumn", false)
    isChange = _data.get("isChange", false)
    currentGradientPos = _data.get("currentGradientPos", 0.0)
    var lineUseData: Array = _data.get("lineUse", [])
    if lineUseData.size() > 0:
        lineUse = lineUseData
    var gridData: Array = _data.get("plantGrid", [])
    for x: int in gridData.size():
        for y: int in gridData[x].size():
            var cellData = gridData[x][y]
            if cellData != null and cellData.size() > 0 and x < plantGrid.size() and y < plantGrid[x].size():
                _LoadCellInto(plantGrid[x][y], cellData, _owner)
    var mowerFeature: TowerDefenseBattleFeatureMower = TowerDefenseManager.GetMowerFeature()
    if mowerFeature:
        mowerFeature.mowerHasRun = _data.get("mowerHasRun", false)
        mowerFeature.mowerLine.clear()
        for characterName: StringName in _data.get("mowerLine", []):
            if characterName != "" and _owner.charcterDicionary.has(characterName):
                mowerFeature.mowerLine.append(_owner.charcterDicionary[characterName])
            else:
                mowerFeature.mowerLine.append(null)
        mowerFeature.targetZombieLine.clear()
        for characterName: StringName in _data.get("targetZombieLine", []):
            if characterName != "" and _owner.charcterDicionary.has(characterName):
                mowerFeature.targetZombieLine.append(_owner.charcterDicionary[characterName])
            else:
                mowerFeature.targetZombieLine.append(null)
    var brainFeature: TowerDefenseBattleFeatureBrain = TowerDefenseManager.GetBrainFeature()
    if brainFeature:
        brainFeature.brainLine.clear()
        for characterName: StringName in _data.get("brainLine", []):
            if characterName != "" and _owner.charcterDicionary.has(characterName):
                brainFeature.brainLine.append(_owner.charcterDicionary[characterName])
            else:
                brainFeature.brainLine.append(null)
    var changeConfigPath: String = _data.get("changeConfigPath", "")
    if changeConfigPath != "":
        changeConfig = load(changeConfigPath)
    if strigeRow >= 0 && is_instance_valid(currentMap):
        currentMap.UseStripe(strigeRow)
    print("[Load] Feature[Map]加载完成: isSwich=%s, isChange=%s, gridData=%d行, mowerLine=%d, brainLine=%d" % [isSwich, isChange, plantGrid.size(), _data.get("mowerLine", []).size(), _data.get("brainLine", []).size()])

func _SaveCell(cellInstance: TowerDefenseCellInstance) -> Dictionary:
    cellInstance.ClearEmpty()
    var characterListData: Array = []
    for character: TowerDefenseCharacter in cellInstance.characterList:
        if is_instance_valid(character):
            characterListData.append(character.name.validate_node_name())
    var characterSlotDictData: Dictionary = {}
    for character: TowerDefenseCharacter in cellInstance.characterSlotDictionary.keys():
        if is_instance_valid(character):
            var slotChar: TowerDefenseCharacter = cellInstance.characterSlotDictionary[character]
            if is_instance_valid(slotChar):
                characterSlotDictData[character.name.validate_node_name()] = slotChar.name.validate_node_name()
            else:
                characterSlotDictData[character.name.validate_node_name()] = ""
    var slotData: Dictionary = {}
    for _gridType: TowerDefenseEnum.PLANTGRIDTYPE in cellInstance.slot.keys():
        if is_instance_valid(cellInstance.slot[_gridType]):
            slotData[_gridType] = cellInstance.slot[_gridType].name.validate_node_name()
        else:
            slotData[_gridType] = ""
    return {
        "gridType": cellInstance.gridType, 
        "elementFlags": cellInstance.elementFlags, 
        "isWater": cellInstance.isWater, 
        "gridPosX": cellInstance.gridPos.x, 
        "gridPosY": cellInstance.gridPos.y, 
        "characterList": characterListData, 
        "characterSlotDictionary": characterSlotDictData, 
        "slot": slotData, 
        "characterSurround": cellInstance.characterSurround.name.validate_node_name() if is_instance_valid(cellInstance.characterSurround) else "", 
        "characterLadder": cellInstance.characterLadder.name.validate_node_name() if is_instance_valid(cellInstance.characterLadder) else "", 
    }

func _LoadCellInto(cellInstance: TowerDefenseCellInstance, cellData: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    if !is_instance_valid(cellInstance):
        return
    cellInstance.elementFlags = cellData.get("elementFlags", 0)
    cellInstance.isWater = cellData.get("isWater", false)
    cellInstance.characterList.clear()
    cellInstance.characterSlotDictionary.clear()
    cellInstance.slot.clear()
    for characterName: StringName in cellData.get("characterList", []):
        if _owner.charcterDicionary.has(characterName):
            var character: TowerDefenseCharacter = _owner.charcterDicionary[characterName]
            cellInstance.characterList.append(character)
            character.destroy.connect(cellInstance.CharacterDestroy)
            character.cell = cellInstance
    for characterName: StringName in cellData.get("characterSlotDictionary", {}).keys():
        var slotCharName: String = cellData.get("characterSlotDictionary", {})[characterName]
        if _owner.charcterDicionary.has(characterName):
            if slotCharName != "" and _owner.charcterDicionary.has(slotCharName):
                cellInstance.characterSlotDictionary[_owner.charcterDicionary[characterName]] = _owner.charcterDicionary[slotCharName]
            else:
                cellInstance.characterSlotDictionary[_owner.charcterDicionary[characterName]] = null
    for _gridType: int in cellData.get("slot", {}).keys():
        var slotCharName: String = cellData.get("slot", {})[_gridType]
        if slotCharName != "" and _owner.charcterDicionary.has(slotCharName):
            cellInstance.slot[_gridType as TowerDefenseEnum.PLANTGRIDTYPE] = _owner.charcterDicionary[slotCharName]
        else:
            cellInstance.slot[_gridType as TowerDefenseEnum.PLANTGRIDTYPE] = null
    var surroundName: String = cellData.get("characterSurround", "")
    if surroundName != "" and _owner.charcterDicionary.has(surroundName):
        cellInstance.characterSurround = _owner.charcterDicionary[surroundName]
    var ladderName: String = cellData.get("characterLadder", "")
    if ladderName != "" and _owner.charcterDicionary.has(ladderName):
        cellInstance.characterLadder = _owner.charcterDicionary[ladderName]



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    mapControl = TOWER_DEFENSE_MAP_CONTROL.instantiate()
    control.AddNode(mapControl, 0)
    mapControl.mapFeature = self
    var mapName: String = data.get("MapName", "")
    mapConfig = TowerDefenseManager.GetMapConfig(mapName)
    for x in range(GRID_MAX_SIZE):
        plantGrid.append([])
        for y in range(GRID_MAX_SIZE):
            plantGrid[x].append(null)
    for y in range(GRID_MAX_SIZE):
        lineUse.append(false)
    iceCapList.resize(GRID_MAX_SIZE - 2)

func GameInit() -> void :
    mapControl.canvasModulateCharacter = control.characterCanvasModulate
    mapControl.canvasModulateCharacter.visible = GameSaveManager.GetConfigValue("MapEffect")
    MapInit(mapConfig)

func GameInitFromProgress() -> void :
    mapControl.canvasModulateCharacter = control.characterCanvasModulate
    mapControl.canvasModulateCharacter.visible = GameSaveManager.GetConfigValue("MapEffect")
    MapInit(mapConfig)

func Process(_delta: float) -> void :
    mapControl.UpdateCanvasModulate(_delta)
    UpdateSwitchTimer(_delta)
    ProcessInput()

func SyncSerialize() -> Dictionary:
    var result: Dictionary = {}
    var line_use: Array = []
    if is_instance_valid(config):
        for line_id in range(1, config.gridNum.y + 1):
            line_use.append(TowerDefenseManager.GetMapLineUse(line_id))
    result["line_use"] = line_use
    if isSwich:
        result["is_swich"] = isSwich
        result["switch_timer"] = snappedf(switchTimer, 0.1)
        result["is_change"] = isChange
        if is_instance_valid(changeConfig):
            result["change_config_path"] = changeConfig.resource_path
    return result

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("line_use") and is_instance_valid(config):
        var line_use: Array = _data["line_use"]
        for i in range(min(line_use.size(), config.gridNum.y)):
            TowerDefenseManager.SetMapLineUse(i + 1, line_use[i])
    if _data.has("is_swich"):
        isSwich = _data["is_swich"]
    if _data.has("switch_timer"):
        switchTimer = _data["switch_timer"]
    if _data.has("is_change"):
        isChange = _data["is_change"]
    if _data.has("change_config_path"):
        var config_path: String = _data["change_config_path"]
        if config_path != "" and ResourceLoader.exists(config_path):
            changeConfig = load(config_path)



func MapInit(_config: TowerDefenseMapConfig) -> void :
    config = _config
    if !is_instance_valid(firstConfig):
        firstConfig = _config
    UpdateIsPlantColumn()
    PlantGridInit()
    MapChange(_config)
    rect = Rect2(-100, _config.edge.y, _config.edge.z + 100, _config.edge.w - _config.edge.y)
    groundRect = Rect2(_config.gridBeginPos.x, _config.gridBeginPos.y, _config.gridBeginPos.x + _config.gridSize.x * _config.gridNum.x, _config.gridBeginPos.y + _config.gridSize.y * _config.gridNum.y)

func UpdateIsPlantColumn() -> void :
    isPlantColumn = is_instance_valid(TowerDefenseManager.currentControl) && TowerDefenseManager.currentControl.levelConfig.plantColumn

func GetGroundHeight(_cell: TowerDefenseCellInstance) -> float:
    if is_instance_valid(_cell.groundHeightCurve):
        return _cell.groundHeightCurve.curve.sample(0.5) * mapControl.global_scale.y
    return 0.0

func PlantGridInit() -> void :
    for x in range(1, config.gridNum.x + 1):
        for y in range(1, config.gridNum.y + 1):
            plantGrid[x][y] = TowerDefenseCellInstance.new()
            plantGrid[x][y].gridPos = Vector2i(x, y)
    for cellConfig: TowerDefenseCellConfig in config.cellConfig:
        SetGridType(cellConfig)
    for line: int in config.lineUse:
        SetLineUse(line, true)

func ProcessInput() -> void :
    var mousePos: Vector2 = mapControl.get_global_mouse_position()
    var gridPos: Vector2i = TowerDefenseManager.GetMapGridPosFromMouse(mousePos)
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    if TowerDefenseManager.IsGameRunning():
        var mowerFeature: TowerDefenseBattleFeatureMower = TowerDefenseManager.GetMowerFeature()
        if is_instance_valid(mowerFeature) && is_instance_valid(mowerFeature.mowerManager):
            mowerFeature.mowerManager.ProcessMowerInput(cell, gridPos)
    if is_instance_valid(packetPickControl) && packetPickControl.packetPick != null:
        if packetPickControl.ProcessPacketPick(cell, gridPos, mousePos):
            return
    if is_instance_valid(packetPickControl):
        packetPickControl.ProcessTools(cell, gridPos, mousePos)
        packetPickControl.ProcessReleaseInput(mousePos)

func MapChange(_config: TowerDefenseMapConfig, duration: float = 0.0, delay: float = 0.0) -> void :
    changeConfig = _config
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        if !is_instance_valid(mapControl.editorSprite):
            mapControl.editorSprite = Sprite2D.new()
            mapControl.editorSprite.centered = false
            mapControl.mapNode.add_child(mapControl.editorSprite)
        mapControl.editorSprite.texture = _config.mapTexture
        mapControl.editorSprite.position = _config.mapOffset
        mapControl.editorSprite.scale = Vector2.ONE * 600.0 / mapControl.editorSprite.texture.get_height()
        TowerDefenseManager.MapIsChange()
        return
    var refresh: bool = false
    if is_instance_valid(config) || _config.mapScene != config.mapScene:
        if config.gridNum != _config.gridNum:
            TowerDefenseManager.TipsPlay("格子数量不同的地图无法切换", 5.0)
            return
        refresh = true
    if delay != 0.0:
        await mapControl.get_tree().create_timer(delay, false).timeout
    if refresh:
        nextMap = _config.mapScene.instantiate() as TowerDefenseMap
        if is_instance_valid(currentMap):
            if currentMap.stripe.visible == true:
                nextMap.UseStripe(strigeRow)
        mapControl.changeMapLayer.add_child(nextMap)
        currentGradient = nextMap.canvasModulateGradient.duplicate()
    if duration != 0.0:
        currentGradient.gradient.set_color(0, mapControl.canvasModulate.color)
        switchTween = mapControl.create_tween()
        switchTween.set_parallel(true)
        switchTween.tween_property(nextMap, "modulate:a", 1.0, duration).from(0.0)
        switchTween.tween_property(currentMap, "modulate:a", 0.0, duration).from(1.0)
        switchTween.tween_property(self, "currentGradientPos", 1.0, duration).from(0.0)
        isChange = true
        await switchTween.finished
        isChange = false
        config = _config
    else:
        mapControl.canvasModulate.color = currentGradient.gradient.sample(1.0)
        if is_instance_valid(mapControl.canvasModulateCharacter):
            mapControl.canvasModulateCharacter.color = currentGradient.gradient.sample(1.0)
        config = _config
    TowerDefenseManager.MapIsChange()
    if refresh:
        if is_instance_valid(currentMap):
            currentMap.queue_free()
        if is_instance_valid(nextMap):
            currentMap = nextMap
        if is_instance_valid(currentMap):
            currentMap.reparent(mapControl.mapNode)
        nextMap = null

func MapDayNightSwitch(duration: float = 2.0, _switchTimer: float = 100.0) -> void :
    if config.dayNightSwitching == "":
        return
    var _changeConfig: TowerDefenseMapConfig = TowerDefenseManager.GetMapConfig(config.dayNightSwitching)
    if _switchTimer == -1:
        MapChange(_changeConfig, duration)
        isSwich = false
        switchTimer = 0
    else:
        MapChange(_changeConfig, duration)
        if _changeConfig != firstConfig:
            switchTimer = _switchTimer
            isSwich = true
        else:
            isSwich = false
            switchTimer = 0

func UpdateSwitchTimer(delta: float) -> void :
    if isSwich && switchTimer != -1:
        if switchTimer > 0:
            switchTimer -= delta
        else:
            MapChange(firstConfig, 2.0)
            isSwich = false

func SetGridType(cellConfig: TowerDefenseCellConfig) -> void :
    for x in range(cellConfig.pos.x, cellConfig.pos.z + 1):
        for y in range(cellConfig.pos.y, cellConfig.pos.w + 1):
            var cell: TowerDefenseCellInstance = plantGrid[x][y]
            cell.Init(cellConfig)

func SetLineUse(line: int, use: bool) -> void :
    lineUse[line] = use

func LineHasType(line: int, type: TowerDefenseEnum.PLANTGRIDTYPE) -> bool:
    if !is_instance_valid(config):
        return false
    for i in range(1, config.gridNum.x + 1):
        var cell: TowerDefenseCellInstance = plantGrid[i][line]
        if !is_instance_valid(cell):
            continue
        if cell.gridType.has(type):
            return true
    return false

func GetCellPlantNum() -> int:
    if !is_instance_valid(config):
        return 0
    var num: int = 0
    for x in range(1, config.gridNum.x + 1):
        for y in range(1, config.gridNum.y + 1):
            if plantGrid[x][y].HasPlant():
                num += 1
    return num

func SetIceCapPos(line: int, pos: Vector2) -> void :
    if !is_instance_valid(iceCapList[line]):
        iceCapList[line] = TOWER_DEFENSE_ICE_CAP.instantiate()
        iceCapList[line].gridPos = Vector2(0, line)
        iceCapList[line].global_position = Vector2(config.mapSize.x, TowerDefenseManager.GetMapCellPlantPos(Vector2i(0, line)).y)
        mapControl.mapIceCap.add_child(iceCapList[line])
    iceCapList[line].length = max(iceCapList[line].length, config.mapSize.x - pos.x)
