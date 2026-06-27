class_name TowerDefenseBattleFeatureWave extends TowerDefenseBattleFeature

const ZOMBIE_SEAWEED = preload("uid://bpyla4k7iutq3")

signal waveReady()
signal waveBegin(id: int, isBigWave: bool, isFinalWave: bool)
signal bigWaveBegin(bigWaveId: int)
signal final()

static var instance: TowerDefenseBattleFeatureWave = null

var config: TowerDefenseLevelWaveManagerConfig
var currentDynamic: TowerDefenseLevelDynamicConfig
var isSurvival: bool = false
var survivalRunner: TowerDefenseLevelSurvivalRunner
var currentSpawnPoint: int = 0

var isRunning: bool = false
var nextWaveTime: float = 0.0
var timer: float = 0.0
var waveStart: bool = false
var waveFinal: bool = false
var awardTime: bool = false
var awardPos: Vector2 = Vector2.ZERO

var currentWave: int = 0
var currentCharacter: Array[TowerDefenseCharacter]
var currentHpPointTotal: float = 0.0
var currentHpPoint: float = 0.0

var savePitchforkLine: int = -1
var spawnOver: bool = false
var showCharacterList: Array[TowerDefenseCharacter] = []
var awaitSpawn: bool = false
var awaitGravestoneSpawm: bool = false
var awaitGridSpawn: bool = false
var readySetPlantOver: bool = false

var sunFeature: TowerDefenseBattleFeatureSun
var mapFeature: TowerDefenseBattleFeatureMap
var progressFeature: TowerDefenseBattleFeatureProgess
var cameraFeature: TowerDefenseBattleFeatureCamera
var seedBankFeature: TowerDefenseBattleFeatureSeedBank
var packetBankFeature: TowerDefenseBattleFeaturePacketBank
var mowerFeature: TowerDefenseBattleFeatureMower

var levelControl: TowerDefenseInGameLevelControl

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelWaveManagerConfig.new()
    config.Init(data)
    if config.dynamic[TowerDefenseManager.currentDynamicLevel]:
        currentDynamic = config.dynamic[TowerDefenseManager.currentDynamicLevel]
    else:
        currentDynamic = TowerDefenseLevelDynamicConfig.new()

func Ready() -> void :
    instance = self

func SetupUI() -> void :
    await GetTree().physics_frame
    var difficult: String = GameSaveManager.GetKeyValue("CurrentDifficult")
    var difiicultString: String = ""
    match difficult:
        "Normal":
            difiicultString = "正常"
        "Difficult":
            difiicultString = "困难"
        "Ultimate":
            difiicultString = "极限"
    progressFeature.SetDifficultModulate(difficult)
    var text = tr(TowerDefenseManager.currentLevelConfig.levelName).replace("{LevelNumber}", str(TowerDefenseManager.currentLevelConfig.levelNumber))
    progressFeature.SetLevelName(text)
    progressFeature.SetDifficultText(difiicultString)
    if isSurvival:
        progressFeature.SetSurvivalText(survivalRunner.roundNum)

func Refresh() -> void :
    isRunning = false
    waveStart = false
    waveFinal = false
    spawnOver = false
    currentWave = 0
    currentCharacter = []
    currentHpPointTotal = 0.0
    currentHpPoint = 0.0
    awaitSpawn = false
    awaitGravestoneSpawm = false
    awaitGridSpawn = false
    readySetPlantOver = false
    currentSpawnPoint = 0
    if progressFeature:
        progressFeature.ProgressRefresh(isSurvival, survivalRunner.roundNum if isSurvival else 0)
    elif isSurvival:
        progressFeature.SetSurvivalText(survivalRunner.roundNum)

func WavePhysicsProcess(delta: float) -> void :
    if CommandManager.debug && CommandManager.debugWavePaused:
        return
    if !readySetPlantOver:
        return
    if awaitSpawn:
        return
    if awaitGravestoneSpawm:
        return
    if awaitGridSpawn:
        return
    if isRunning && !waveFinal:
        var flagNextWave: bool = false
        var percentage: float = 1.0
        if spawnOver && waveStart:
            if currentHpPointTotal != 0.0:
                percentage = currentHpPoint / currentHpPointTotal
            if GetTree().get_node_count_in_group("Zombie") <= 0:
                if timer > config.spawnColStart:
                    flagNextWave = true
        if timer < nextWaveTime:
            timer += delta
            if percentage < config.maxNextWaveHealthPercentage:
                if timer > config.spawnColStart:
                    flagNextWave = true
            if percentage < config.minNextWaveHealthPercentage:
                flagNextWave = true
        else:
            flagNextWave = true
        if !waveFinal:
            if flagNextWave:
                timer = 0.0
                awaitSpawn = true
                NextWave()

func StartWave() -> void :
    waveReady.emit()
    currentWave = 0
    isRunning = true
    waveStart = false
    currentSpawnPoint = currentDynamic.startingPoints
    nextWaveTime = config.beginCol
    timer = 0
    if isSurvival:
        if survivalRunner.roundNum > 0:
            nextWaveTime = 6.0

func NextWave() -> void :
    if waveFinal:
        return
    spawnOver = false
    if !waveStart:
        AudioManager.AudioPlay("WaveBegin", AudioManagerEnum.TYPE.SFX)
        progressFeature.SetProgressMeterVisible(true)
        var lookStarFeature = GetFeature("LookStar")
        if lookStarFeature && lookStarFeature.IsOpen():
            progressFeature.SetProgressMeterVisible(false)
        waveStart = true
        bigWaveBegin.emit(0)
    if currentWave + 1 >= config.wave.size():
        waveFinal = true
    if (currentWave + 1) % config.flagWaveInterval == 0:
        AudioManager.AudioPlay("WaveHuge", AudioManagerEnum.TYPE.SFX)
        var packetPickControl = TowerDefenseManager.GetPacketPickControl()
        if is_instance_valid(packetPickControl) && packetPickControl.IsPicking():
            packetPickControl.Release()
        if TowerDefenseManager.IsIZM2Mode():
            TowerDefenseManager.TipsPlay("TOWERDEFENSE_TIPS_IZM2_HUGEWAVE", 4.0)
        else:
            TowerDefenseManager.TipsPlay("TOWERDEFENSE_TIPS_HUGEWAVE", 4.0)
        await GetTree().create_timer(4.0, false).timeout
        if !is_instance_valid(control) || !control.isGameRunning:
            return
        AudioManager.AudioPlay("WaveHugeBegin", AudioManagerEnum.TYPE.SFX)

    var flagDynamic: bool = false
    if (currentWave + 1) >= currentDynamic.startingWave:
        currentSpawnPoint += currentDynamic.pointIncrementPerWave
        flagDynamic = true
    if currentWave < config.wave.size():
        Spawn(currentWave, flagDynamic)
        currentWave += 1
    nextWaveTime = config.spawnColEnd
    awaitSpawn = false
    if currentWave == 1:
        nextWaveTime *= 2.0
    if currentWave == 2:
        nextWaveTime *= 1.5
    if currentWave % config.flagWaveInterval == 0:
        nextWaveTime += 5.0
    if currentWave == config.wave.size():
        var lookStarFeature = GetFeature("LookStar")
        if lookStarFeature && lookStarFeature.OnWaveReachFinal(self):
            return
        final.emit()
        AudioManager.AudioPlay("WaveFinal", AudioManagerEnum.TYPE.SFX)
        if !isSurvival:
            TowerDefenseManager.TipsPlay("TOWERDEFENSE_TIPS_FINALWAVE", 2.0)
        elif survivalRunner.config.roundLimit != -1 && survivalRunner.roundNum + 1 >= survivalRunner.config.roundLimit:
            TowerDefenseManager.TipsPlay("TOWERDEFENSE_TIPS_FINALWAVE", 2.0)

func AddSpawnCharacter(character) -> void :
    var hp: float = character.GetTotalHitPoint()
    currentHpPointTotal += hp
    currentHpPoint += hp
    character.bodyHurt.connect(HpPointDecrease)
    character.armorHurt.connect(HpPointDecrease)
    character.destroy.connect(CharacterDestroy)
    currentCharacter.append(character)

func Spawn(waveId: int, dynamic: bool = false) -> void :
    spawnOver = false
    progressFeature.SetProgressMeterWaveCurrent(waveId + 1)
    var isHugeWave: bool = (waveId + 1) % config.flagWaveInterval == 0
    var isFinalWave: bool = waveId + 1 == config.wave.size()
    waveBegin.emit(waveId + 1, isHugeWave, isFinalWave)
    if isSurvival:
        survivalRunner.WaveReach(waveId + 1, isHugeWave)
    if isHugeWave:
        bigWaveBegin.emit(int(float(waveId + 1) / config.flagWaveInterval))
    for character: TowerDefenseCharacter in currentCharacter:
        if !character:
            character = null
        if character:
            if character.bodyHurt.is_connected(HpPointDecrease):
                character.bodyHurt.disconnect(HpPointDecrease)
            if character.armorHurt.is_connected(HpPointDecrease):
                character.armorHurt.disconnect(HpPointDecrease)
            if character.destroy.is_connected(CharacterDestroy):
                character.destroy.disconnect(CharacterDestroy)
    currentCharacter.clear()
    currentHpPointTotal = 0

    WaveEventExecute(waveId)
    SpawnGrid(waveId)
    await SpawnZombie(waveId, dynamic)
    await GetTree().physics_frame
    if !is_instance_valid(control) || !control.isGameRunning:
        return
    if levelControl.awardCreate:
        return
    if currentWave - 1 == waveId:
        spawnOver = true
        currentHpPoint = currentHpPointTotal

func WaveEventExecute(waveId: int) -> void :
    var wave: TowerDefenseLevelWaveConfig = config.wave[waveId]
    for event: TowerDefenseLevelEventBase in wave.event:
        event.Execute()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var events_data: Array = []
        for event: TowerDefenseLevelEventBase in wave.event:
            events_data.append(event.Export())
        if events_data.size() > 0:
            MultiPlayerManager.SendWaveEventExecute(waveId, JSON.stringify(events_data))

func SpawnZombie(waveId: int, dynamic: bool = false) -> void :
    if CommandManager.debug && CommandManager.debugNoZombieSpawn:
        return
    if levelControl.awardCreate:
        return
    var isHugeWave: bool = (waveId + 1) % config.flagWaveInterval == 0
    var wave: TowerDefenseLevelWaveConfig = config.wave[waveId]

    var flag: bool = false
    for lineId in mapFeature.config.gridNum.y:
        if mapFeature.lineUse[lineId + 1]:
            flag = true
            break
    if !flag:
        return

    var spawnPoint: int = currentSpawnPoint
    var spawnPointMin: int = 100000000
    var spawnList: Array = []
    spawnList.resize(26)
    if wave.dynamic:
        spawnPoint += wave.dynamic.points
    if isSurvival:
        if isHugeWave:
            spawnPoint += floor(survivalRunner.point * survivalRunner.config.pointBigWaveScale)
        else:
            spawnPoint += survivalRunner.point
    for spawnLine: int in mapFeature.config.gridNum.y:
        spawnList[spawnLine + 1] = []

    if config.flagZombieUse:
        if isHugeWave && config.flagZombie != "":
            var spawnLinePick: int = 1 + randi() % mapFeature.config.gridNum.y
            var minNum: int = 10000
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(config.flagZombie)
            var checkList: Array = []
            for lineId in mapFeature.config.gridNum.y:
                if mapFeature.lineUse[lineId + 1]:
                    minNum = min(minNum, spawnList[lineId + 1].size())
            for lineId in mapFeature.config.gridNum.y:
                checkList.append(lineId + 1)
            spawnLinePick = checkList.pick_random()
            checkList.erase(spawnLinePick)
            while (checkList.size() > 0 && ( !mapFeature.lineUse[spawnLinePick]\
|| (minNum != spawnList[spawnLinePick].size() && !packetConfig.HasSpawnLimit())\
|| !packetConfig.CanSpawn(spawnLinePick))):
                spawnLinePick = checkList.pick_random()
                checkList.erase(spawnLinePick)
            var spawn: TowerDefenseLevelSpawnConfig = TowerDefenseLevelSpawnConfig.new()
            spawn.zombie = config.flagZombie
            spawnList[spawnLinePick].append(spawn)
    wave.spawn.shuffle()
    if !isSurvival:
        for spawn: TowerDefenseLevelSpawnConfig in wave.spawn:
            for i in spawn.num:
                if savePitchforkLine != -1:
                    spawnList[savePitchforkLine].append(spawn)
                    savePitchforkLine = -1
                elif spawn.line != -1:
                    spawnList[spawn.line].append(spawn)
                else:
                    var spawnLinePick: int = 1 + randi() % mapFeature.config.gridNum.y
                    var minNum: int = 10000
                    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(spawn.zombie)
                    var checkList: Array = []
                    for lineId in mapFeature.config.gridNum.y:
                        if mapFeature.lineUse[lineId + 1]:
                            minNum = min(minNum, spawnList[lineId + 1].size())
                        checkList.append(lineId + 1)
                    spawnLinePick = checkList.pick_random()
                    checkList.erase(spawnLinePick)
                    while (checkList.size() > 0 && ( !mapFeature.lineUse[spawnLinePick]\
|| (minNum != spawnList[spawnLinePick].size() && !packetConfig.HasSpawnLimit())\
|| !packetConfig.CanSpawn(spawnLinePick))):
                        spawnLinePick = checkList.pick_random()
                        checkList.erase(spawnLinePick)
                    spawnList[spawnLinePick].append(spawn)

    if dynamic || wave.dynamic || isSurvival:
        var weightPick: Array[WeightPickItemBase] = []
        var zombiePool: Array[String] = currentDynamic.zombiePool.duplicate_deep()
        if wave.dynamic:
            zombiePool.append_array(wave.dynamic.zombiePool)
        if isSurvival:
            zombiePool.append_array(survivalRunner.currentZombiePool)
        if zombiePool.size() > 0:
            for zombieName: String in zombiePool:
                var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombieName)
                var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
                var spawn: TowerDefenseLevelSpawnConfig = TowerDefenseLevelSpawnConfig.new()
                spawn.zombie = zombieName
                if characterConfig is TowerDefenseZombieConfig:
                    var weight: int = packetConfig.GetWeight()
                    var weightPickItem: WeightPickItemBase = WeightPickItemBase.new(spawn, weight)
                    spawnPointMin = min(spawnPointMin, packetConfig.GetWavePointCost())
                    weightPick.append(weightPickItem)
            if spawnPoint > 0:
                while (spawnPoint >= spawnPointMin):
                    var item: WeightPickItemBase = WeightPickMathine.Pick(weightPick)
                    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(item.item.zombie)
                    var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
                    var pointCost: int = int(item.weight)
                    if characterConfig is TowerDefenseZombieConfig:
                        pointCost = packetConfig.GetWavePointCost()
                    if spawnPoint < pointCost:
                        continue
                    spawnPoint -= pointCost
                    var spawnLinePick: int = 1 + randi() % mapFeature.config.gridNum.y
                    var minNum: int = 10000
                    var checkList: Array = []
                    for lineId in mapFeature.config.gridNum.y:
                        if mapFeature.lineUse[lineId + 1]:
                            minNum = min(minNum, spawnList[lineId + 1].size())
                        checkList.append(lineId + 1)
                    spawnLinePick = checkList.pick_random()
                    checkList.erase(spawnLinePick)
                    while (checkList.size() > 0 && ( !mapFeature.lineUse[spawnLinePick]\
|| (minNum != spawnList[spawnLinePick].size() && !packetConfig.HasSpawnLimit())\
|| !packetConfig.CanSpawn(spawnLinePick))):
                        spawnLinePick = checkList.pick_random()
                        checkList.erase(spawnLinePick)
                    spawnList[spawnLinePick].append(item.item)
            else:
                spawnPoint = - spawnPoint
                while (spawnPoint >= spawnPointMin):
                    var item: WeightPickItemBase = WeightPickMathine.Pick(weightPick)
                    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(item.item.zombie)
                    var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
                    var pointCost: int = int(item.weight)
                    if characterConfig is TowerDefenseZombieConfig:
                        pointCost = packetConfig.GetWavePointCost()
                    if spawnPoint < pointCost:
                        continue
                    var hasFlag: bool = false
                    for lineId in mapFeature.config.gridNum.y:
                        if mapFeature.lineUse[lineId + 1]:
                            var spawnLineListCheck: Array = spawnList[lineId + 1]
                            for spawn: TowerDefenseLevelSpawnConfig in spawnLineListCheck:
                                if spawn.zombie == item.item && spawn.spawnEvent.size() <= 0 && spawn.dieEvent.size() <= 0:
                                    hasFlag = true
                                    break
                            if hasFlag:
                                break
                    if !hasFlag:
                        continue
                    spawnPoint -= pointCost

                    var spawnLinePick: int = 1 + randi() % mapFeature.config.gridNum.y
                    var spawnLineList: Array = spawnList[spawnLinePick]
                    while ( !mapFeature.lineUse[spawnLinePick]):
                        var checkHasFlag: bool = false
                        for spawn: TowerDefenseLevelSpawnConfig in spawnLineList:
                            if spawn.zombie == item.item && spawn.spawnEvent.size() <= 0 && spawn.dieEvent.size() <= 0:
                                checkHasFlag = true
                                break
                        if checkHasFlag:
                            break
                        spawnLinePick = 1 + randi() % mapFeature.config.gridNum.y
                        spawnLineList = spawnList[spawnLinePick]
                    for spawn: TowerDefenseLevelSpawnConfig in spawnLineList:
                        if spawn.zombie == item.item && spawn.spawnEvent.size() <= 0 && spawn.dieEvent.size() <= 0:
                            spawnList[spawnLinePick].erase(spawn)
                            break

    var maxNum: int = 0
    for spawnLine: int in mapFeature.config.gridNum.y:
        var spawnLineList: Array = spawnList[spawnLine + 1]
        spawnLineList.shuffle()
        maxNum = max(maxNum, spawnLineList.size())

    for spawnNameId in maxNum:
        for spawnLine: int in mapFeature.config.gridNum.y:
            var spawnLineList: Array = spawnList[spawnLine + 1]
            if spawnNameId < spawnLineList.size():
                var spawn: TowerDefenseLevelSpawnConfig = spawnLineList[spawnNameId]
                var spawnName: String = spawn.zombie
                if spawnName == "":
                    continue
                var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(spawnName)
                var spawnOffsetX: float = spawnNameId * 60.0 + randf() * 60.0
                var multiplayerCount: int = 2 if Global.isMultiplayerMode else 1
                for _mpi in multiplayerCount:
                    var _spawnLine: int = spawnLine
                    var _spawnOffsetX: float = spawnOffsetX
                    if Global.isMultiplayerMode and _mpi == 1:
                        _spawnLine = randi_range(0, mapFeature.config.gridNum.y - 1)
                        _spawnOffsetX = spawnNameId * 60.0 + randf() * 60.0
                    var character: TowerDefenseCharacter = packetConfig.Spawn(_spawnLine + 1, _spawnOffsetX)
                    character.invisible = config.zombieInvisible
                    if is_instance_valid(config.spawnOverride):
                        config.spawnOverride.ExecuteCharacter(character)
                    if is_instance_valid(spawn.override):
                        spawn.override.ExecuteCharacter(character)
                    for event: TowerDefenseCharacterEventBase in spawn.spawnEvent:
                        event.Execute(character.global_position, character)
                    character.dieEvent.append_array(spawn.dieEvent)

                    if character is TowerDefenseZombie && !TowerDefenseManager.IsIZM2Mode():
                        currentHpPointTotal += character.GetTotalHitPoint()
                        character.bodyHurt.connect(HpPointDecrease)
                        character.armorHurt.connect(HpPointDecrease)
                        character.destroy.connect(CharacterDestroy)
                        currentCharacter.append(character)
                    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                        var sync_id: int = TowerDefenseManager.currentControl._get_next_sync_id()
                        var _spawn_override_data: String = ""
                        var _spawn_config_override_data: String = ""
                        if is_instance_valid(config.spawnOverride):
                            _spawn_override_data = JSON.stringify(config.spawnOverride.Export())
                        if is_instance_valid(spawn.override):
                            _spawn_config_override_data = JSON.stringify(spawn.override.Export())
                        MultiPlayerManager.SendSpawnZombie(spawnName, _spawnLine + 1, _spawnOffsetX, sync_id, _spawn_override_data, _spawn_config_override_data)
                        TowerDefenseManager.currentControl._register_sync_character(sync_id, character)
        await GetTree().create_timer(0.1, false).timeout
        if !is_instance_valid(control) || !control.isGameRunning:
            return

func SpawnGrid(waveId: int) -> void :
    if !is_instance_valid(control) || !control.isGameRunning:
        return
    var gridNum: Vector2i = mapFeature.config.gridNum
    var emptyCell: Array[TowerDefenseCellInstance] = []
    for x in range(1, gridNum.x + 1):
        for y in range(1, gridNum.y + 1):
            if !mapFeature.lineUse[y]:
                continue
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(Vector2i(x, y))
            if !cell:
                continue
            if cell.characterList.is_empty():
                emptyCell.append(cell)
    var wave: TowerDefenseLevelWaveConfig = config.wave[waveId]
    for spawn: TowerDefenseLevelGridSpawnConfig in wave.gridSpawn:
        var gridPos: Vector2i = spawn.gridPos
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
        if !cell:
            continue
        emptyCell.erase(cell)
    for spawn: TowerDefenseLevelGridSpawnConfig in wave.gridSpawn:
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(spawn.packet)
        var gridPos: Vector2i = spawn.gridPos
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
        if !cell:
            continue
        var canSpawnFlag: bool = true
        if !packetConfig.characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.ALL):
            if !cell.CanPacketPlant(packetConfig, false, false):
                canSpawnFlag = false
                for _cell: TowerDefenseCellInstance in emptyCell:
                    if cell.CanMoveToCell(_cell):
                        cell.MoveToCell(_cell, true)
                        canSpawnFlag = true
                        emptyCell.erase(_cell)
                        break

        if !canSpawnFlag:
            continue
        if cell.CanPacketPlant(packetConfig, false, false):
            var character: TowerDefenseCharacter = packetConfig.Plant(gridPos, true, true)

            if is_instance_valid(config.spawnOverride):
                config.spawnOverride.ExecuteCharacter(character)
            if is_instance_valid(spawn.override):
                spawn.override.ExecuteCharacter(character)
            for event: TowerDefenseCharacterEventBase in spawn.spawnEvent:
                event.Execute(character.global_position, character)
            character.dieEvent.append_array(spawn.dieEvent)

            if character is TowerDefensePlant && TowerDefenseManager.IsIZM2Mode():
                currentHpPointTotal += character.GetTotalHitPoint()
                character.bodyHurt.connect(HpPointDecrease)
                character.armorHurt.connect(HpPointDecrease)
                character.destroy.connect(CharacterDestroy)
                currentCharacter.append(character)
            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                var sync_id: int = TowerDefenseManager.currentControl._get_next_sync_id()
                MultiPlayerManager.SendSpawnGrid(spawn.packet, gridPos.x, gridPos.y, sync_id)
                if is_instance_valid(character):
                    TowerDefenseManager.currentControl._register_sync_character(sync_id, character)

func HpPointDecrease(num: int) -> void :
    currentHpPoint -= num

func CharacterDestroy(character: TowerDefenseCharacter) -> void :
    currentHpPoint -= character.GetCurrentHitPoint()
    currentCharacter.erase(character)

func ShowCharacter() -> void :
    var currentdynamic: TowerDefenseLevelDynamicConfig = config.dynamic[TowerDefenseManager.currentDynamicLevel]

    var _showCharacterList: Array[String] = []
    var showCharacterNumDictionary: Dictionary = {}
    var posList: Array[Vector2i] = []
    var dynamicList: Array[String] = []
    if currentdynamic:
        dynamicList.append_array(currentdynamic.zombiePool)
    if isSurvival:
        dynamicList.append_array(survivalRunner.currentZombiePool)
    if !isSurvival:
        for wave: TowerDefenseLevelWaveConfig in config.wave:
            for spawn: TowerDefenseLevelSpawnConfig in wave.spawn:
                var charcterName: String = spawn.zombie
                if !_showCharacterList.has(charcterName):
                    _showCharacterList.append(charcterName)
                    showCharacterNumDictionary[charcterName] = 0
                showCharacterNumDictionary[charcterName] += 1
            dynamicList.append_array(wave.dynamic.zombiePool)

    for charcterName: String in dynamicList:
        if !_showCharacterList.has(charcterName):
            _showCharacterList.append(charcterName)
            showCharacterNumDictionary[charcterName] = 0
        showCharacterNumDictionary[charcterName] += 1

    for characterName: String in _showCharacterList:
        var pos: Vector2i = Vector2i(randi_range(0, 3), randi_range(1, mapFeature.config.gridNum.y))
        while posList.has(pos):
            pos = Vector2i(randi_range(0, 3), randi_range(1, mapFeature.config.gridNum.y))
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(characterName)
        var spawnPosX: float = pos.x * 60
        if pos.y % 2 == 0:
            spawnPosX -= 30
        var character: TowerDefenseCharacter = packetConfig.Spawn(pos.y, spawnPosX, true)
        character.isShow = true
        character.invisible = config.zombieInvisible
        if is_instance_valid(config.spawnOverride):
            config.spawnOverride.ExecuteCharacter(character)
        character.gridPos = Vector2i(-1, -1)
        showCharacterList.append(character)
        posList.append(pos)
        if posList.size() >= 4 * mapFeature.config.gridNum.y:
            break

    if _showCharacterList.size() > 0 && _showCharacterList.size() < 8:
        var weightPick: Array[WeightPickItemBase] = []
        for characterName: String in _showCharacterList:
            var weightItem: WeightPickItemBase = WeightPickItemBase.new(characterName, showCharacterNumDictionary[characterName])
            weightPick.append(weightItem)
        for id in 8 - _showCharacterList.size():
            var characterName: String = WeightPickMathine.Pick(weightPick).item
            var pos: Vector2i = Vector2i(randi_range(0, 3), randi_range(1, mapFeature.config.gridNum.y))
            while posList.has(pos):
                pos = Vector2i(randi_range(0, 3), randi_range(1, mapFeature.config.gridNum.y))
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(characterName)
            if !packetConfig.characterConfig.preview:
                continue
            var spawnPosX: float = pos.x * 60
            if pos.y % 2 == 0:
                spawnPosX -= 30
            var character: TowerDefenseCharacter = packetConfig.Spawn(pos.y, spawnPosX, true)
            character.isShow = true
            character.invisible = config.zombieInvisible
            if is_instance_valid(config.spawnOverride):
                config.spawnOverride.ExecuteCharacter(character)

            character.gridPos = Vector2i(-1, -1)
            showCharacterList.append(character)
            posList.append(pos)

func ClearShowCharacter() -> void :
    for character: TowerDefenseCharacter in showCharacterList:
        if is_instance_valid(character):
            TowerDefenseManager.CharacterUnregister(character)
            character.remove_from_group("Character")
            character.queue_free()

func GravestoneSpawn(zombieNames: Array, zombieNum: int, delay: Vector2, override: TowerDefenseCharacterOverride) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    awaitGravestoneSpawm = true
    var weightPick: Array[WeightPickItemBase] = []
    if zombieNames.size() > 0:
        for zombieName: String in zombieNames:
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombieName)
            var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
            if characterConfig is TowerDefenseZombieConfig:
                var weight: int = characterConfig.weight
                if packetConfig.overrideWeight != -1:
                    weight = packetConfig.overrideWeight
                var weightPickItem: WeightPickItemBase = WeightPickItemBase.new(zombieName, weight)
                weightPick.append(weightPickItem)
        var cansSpawnPos: Array[Vector2i] = []
        var gravestoneList = Global.get_tree().get_nodes_in_group("Gravestone")
        for gravestone in gravestoneList:
            if gravestone is TowerDefenseGravestone:
                cansSpawnPos.append(gravestone.gridPos)
        var num: int = min(cansSpawnPos.size(), zombieNum)
        while (num > 0):
            var spawnTimer: float = randf_range(delay.x, delay.y)
            var _cansSpawnPos: Array[Vector2i] = cansSpawnPos.duplicate()
            var _weightPick = weightPick
            var _override = override
            TowerDefenseManager.currentControl.get_tree().create_timer(spawnTimer, false).timeout.connect(
                func():
                    if levelControl.awardCreate:
                        return
                    var checkGravestoneList = Global.get_tree().get_nodes_in_group("Gravestone")
                    var checkPos: Array[Vector2i] = []
                    for gravestone in checkGravestoneList:
                        if gravestone is TowerDefenseGravestone:
                            checkPos.append(gravestone.gridPos)
                    var item: WeightPickItemBase = WeightPickMathine.Pick(_weightPick)
                    var packet: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(item.item)
                    var gridPos: Vector2i = _cansSpawnPos.pick_random()
                    if checkPos.has(gridPos):
                        AudioManager.AudioPlay("GravestoneRumble", AudioManagerEnum.TYPE.SFX)
                        var zombie: TowerDefenseZombie = packet.Plant(gridPos, false) as TowerDefenseZombie
                        var rise_duration: float = randf_range(0.4, 0.6)
                        zombie.Rise(rise_duration)
                        if _override:
                            _override.ExecuteCharacter(zombie)
                        AddSpawnCharacter(zombie)
                        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                            if is_instance_valid(control):
                                var _sync_id: int = control._get_next_sync_id()
                                var _hitpoint_scale: float = zombie.instance.hitpointScale if is_instance_valid(zombie.instance) else 1.0
                                var _scale: float = zombie.transformPoint.scale.x if is_instance_valid(zombie.transformPoint) else 1.0
                                control._register_sync_character(_sync_id, zombie)
                                MultiPlayerManager.SendSpawnCharacterAt(item.item, gridPos.x, gridPos.y, _sync_id, _hitpoint_scale, _scale, false, rise_duration)
                    _cansSpawnPos.erase(gridPos)
            )
            num -= 1
        await GetTree().create_timer(delay.y, false).timeout
        if !is_instance_valid(control) || !control.isGameRunning:
            return
        awaitGravestoneSpawm = false

func GridSpawnZombie(zombieNames: Array, zombieNum: int, delay: Vector2, override: TowerDefenseCharacterOverride, spawnPos: Vector4i, spawnType: String) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    awaitGridSpawn = true
    var weightPick: Array[WeightPickItemBase] = []
    if zombieNames.size() > 0:
        for zombieName: String in zombieNames:
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(zombieName)
            var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
            if characterConfig is TowerDefenseZombieConfig:
                var weight: int = characterConfig.weight
                if packetConfig.overrideWeight != -1:
                    weight = packetConfig.overrideWeight
                var weightPickItem: WeightPickItemBase = WeightPickItemBase.new(zombieName, weight)
                weightPick.append(weightPickItem)
        var cansSpawnPos: Array[Vector2i] = []
        for x in range(spawnPos.x, spawnPos.z + 1):
            for y in range(spawnPos.y, spawnPos.w + 1):
                var gridPos: Vector2i = Vector2i(x, y)
                var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
                if is_instance_valid(cell):
                    cansSpawnPos.append(gridPos)
        var num: int = min(cansSpawnPos.size(), zombieNum)
        while (num > 0):
            var spawnTimer: float = randf_range(delay.x, delay.y)
            var _cansSpawnPos: Array[Vector2i] = cansSpawnPos.duplicate()
            var _weightPick = weightPick
            var _override = override
            var _spawnType = spawnType
            TowerDefenseManager.currentControl.get_tree().create_timer(spawnTimer, false).timeout.connect(
                func():
                    if levelControl.awardCreate:
                        return
                    if _cansSpawnPos.size() <= 0:
                        return
                    var item: WeightPickItemBase = WeightPickMathine.Pick(_weightPick)
                    var gridPos: Vector2i = _cansSpawnPos.pick_random()
                    match _spawnType:
                        "Bungi":
                            TowerDefenseManager.BungiSpawn(item.item, gridPos, _override)
                        _:
                            AudioManager.AudioPlay("GravestoneRumble", AudioManagerEnum.TYPE.SFX)
                            var packet: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(item.item)
                            var zombie: TowerDefenseZombie = packet.Plant(gridPos, false) as TowerDefenseZombie
                            var rise_duration: float = randf_range(0.4, 0.6)
                            zombie.Rise(rise_duration)
                            var _cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
                            if is_instance_valid(_cell) && _cell.IsWater():
                                var zombieScale: float = zombie.scale.x * zombie.sprite.scale.x
                                var baseFlip: int = -1 if zombie.sprite.scale.x < 0 else 1
                                var seaweedPositions: Array = [
                                    {"frame": 0, "offset": Vector2(-30, -10), "flip": true, "scale_mul": 1.0}, 
                                    {"frame": 1, "offset": Vector2(-20, 20), "flip": false, "scale_mul": 0.9}, 
                                    {"frame": 2, "offset": Vector2(25, -20), "flip": true, "scale_mul": 1.1}, 
                                    {"frame": 3, "offset": Vector2(30, 15), "flip": false, "scale_mul": 0.85}, 
                                ]
                                var anchorPos: Vector2 = zombie.sprite.global_position
                                if is_instance_valid(zombie.headSlot):
                                    zombie.headSlot.Update()
                                    anchorPos = zombie.headSlot.global_position
                                for seaweedData: Dictionary in seaweedPositions:
                                    var seaweedSprite: Sprite2D = Sprite2D.new()
                                    seaweedSprite.texture = ZOMBIE_SEAWEED
                                    seaweedSprite.hframes = 4
                                    seaweedSprite.frame = seaweedData["frame"]
                                    var flipSign: int = -1 if seaweedData["flip"] else 1
                                    seaweedSprite.scale.x = zombieScale * seaweedData["scale_mul"] * flipSign * baseFlip
                                    seaweedSprite.scale.y = zombieScale * seaweedData["scale_mul"]
                                    zombie.spriteGroup.add_child(seaweedSprite)
                                    seaweedSprite.global_position = anchorPos + Vector2(seaweedData["offset"].x * baseFlip, seaweedData["offset"].y)
                            if _override:
                                _override.ExecuteCharacter(zombie)
                            AddSpawnCharacter(zombie)
                            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                                if is_instance_valid(control):
                                    var _sync_id: int = control._get_next_sync_id()
                                    var _hitpoint_scale: float = zombie.instance.hitpointScale if is_instance_valid(zombie.instance) else 1.0
                                    var _scale: float = zombie.transformPoint.scale.x if is_instance_valid(zombie.transformPoint) else 1.0
                                    control._register_sync_character(_sync_id, zombie)
                                    MultiPlayerManager.SendSpawnCharacterAt(item.item, gridPos.x, gridPos.y, _sync_id, _hitpoint_scale, _scale, false, rise_duration)
                    _cansSpawnPos.erase(gridPos)
            )
            num -= 1
        await GetTree().create_timer(delay.y, false).timeout
        if !is_instance_valid(control) || !control.isGameRunning:
            return
        awaitGridSpawn = false

func GameInit() -> void :
    levelControl = control.levelControl

    sunFeature = GetFeature("Sun")
    mapFeature = GetFeature("Map")
    progressFeature = GetFeature("Progess")
    cameraFeature = GetFeature("Camera")
    seedBankFeature = GetFeature("SeedBank")
    packetBankFeature = GetFeature("PacketBank")
    mowerFeature = GetFeature("Mower")

    progressFeature.ProgressInit(config.wave.size(), config.flagWaveInterval)
    if config.survival != "" || is_instance_valid(config.customSurvival):
        isSurvival = true
        survivalRunner = TowerDefenseLevelSurvivalRunner.new()
        if config.isCustomSurvival:
            survivalRunner.Init(config.customSurvival)
        else:
            var survivalConfig: TowerDefenseLevelSurvivalConfig = ResourceManager.SURVIVALS[config.survival]
            survivalConfig.Init()
            survivalRunner.Init(survivalConfig)
    SetupUI()

func GameInitFromProgress() -> void :
    levelControl = control.levelControl

    sunFeature = GetFeature("Sun")
    mapFeature = GetFeature("Map")
    progressFeature = GetFeature("Progess")
    cameraFeature = GetFeature("Camera")
    seedBankFeature = GetFeature("SeedBank")
    packetBankFeature = GetFeature("PacketBank")
    mowerFeature = GetFeature("Mower")

    if config.survival != "" || is_instance_valid(config.customSurvival):
        isSurvival = true
        survivalRunner = TowerDefenseLevelSurvivalRunner.new()
        if config.isCustomSurvival:
            survivalRunner.Init(config.customSurvival)
        else:
            var survivalConfig: TowerDefenseLevelSurvivalConfig = ResourceManager.SURVIVALS[config.survival]
            survivalConfig.Init()
            survivalRunner.Init(survivalConfig)
    progressFeature.ProgressInit(config.wave.size(), config.flagWaveInterval)
    SetupUI()

func GameStart() -> void :
    StartWave()

func GameStartFromProgress() -> void :
    progressFeature.SetProgressMeterVisible(true)
    if isSurvival:
        progressFeature.SetSurvivalVisible(true)
    if is_instance_valid(progressFeature) and is_instance_valid(progressFeature.progessManager) and is_instance_valid(progressFeature.progessManager.progressMeter):
        progressFeature.progessManager.progressMeter.previewWave = currentWave

func SurvivalReady() -> void :
    ClearShowCharacter()
    progressFeature.SetDifficultVisible(true)
    if isSurvival:
        progressFeature.SetSurvivalVisible(true)
    ShowInformation()
    ReadyEventExecute()

func ShowInformation() -> void :
    progressFeature.SetLevelNameVisible(true)
    if Global.enterLevelMode == "DailyLevel" || Global.enterLevelMode == "OnlineLevel" || Global.enterLevelMode == "LevelTest" || Global.enterLevelMode == "DiyLevel":
        progressFeature.SetDifficultVisible(false)

func ReadyEventExecute() -> void :
    if data.has("EventReady"):
        await TowerDefenseManager.ExecuteLevelEvent(data["EventReady"])

func SyncSerialize() -> Dictionary:
    return {
        "current_wave": currentWave, 
        "wave_final": waveFinal, 
        "spawn_over": spawnOver, 
        "timer": snappedf(timer, 1.0), 
        "next_wave_time": nextWaveTime, 
        "is_running": isRunning, 
        "wave_start": waveStart, 
        "current_spawn_point": currentSpawnPoint, 
        "await_spawn": awaitSpawn, 
        "current_hp_point_total": currentHpPointTotal, 
        "current_hp_point": currentHpPoint, 
    }

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("current_wave"):
        currentWave = _data["current_wave"]
    if _data.has("wave_final"):
        waveFinal = _data["wave_final"]
    if _data.has("spawn_over"):
        spawnOver = _data["spawn_over"]
    if _data.has("timer"):
        timer = _data["timer"]
    if _data.has("next_wave_time"):
        nextWaveTime = _data["next_wave_time"]
    if _data.has("is_running"):
        isRunning = _data["is_running"]
    if _data.has("wave_start"):
        waveStart = _data["wave_start"]
    if _data.has("current_spawn_point"):
        currentSpawnPoint = _data["current_spawn_point"]
    if _data.has("await_spawn"):
        awaitSpawn = _data["await_spawn"]
    if _data.has("current_hp_point_total"):
        currentHpPointTotal = _data["current_hp_point_total"]
    if _data.has("current_hp_point"):
        currentHpPoint = _data["current_hp_point"]
    if is_instance_valid(progressFeature):
        progressFeature.SetProgressMeterWaveCurrent(currentWave)
        progressFeature.SetProgressMeterVisible(waveStart)

func SaveFeature() -> Dictionary:
    print("[Save] 保存Feature[Wave]...")
    var currentCharacterNames: Array = []
    for character: TowerDefenseCharacter in currentCharacter:
        if is_instance_valid(character):
            currentCharacterNames.append(character.name.validate_node_name())
    var result: Dictionary = {
        "currentWave": currentWave, 
        "waveFinal": waveFinal, 
        "waveStart": waveStart, 
        "spawnOver": spawnOver, 
        "timer": timer, 
        "nextWaveTime": nextWaveTime, 
        "isRunning": isRunning, 
        "currentSpawnPoint": currentSpawnPoint, 
        "currentHpPointTotal": currentHpPointTotal, 
        "currentHpPoint": currentHpPoint, 
        "isSurvival": isSurvival, 
        "savePitchforkLine": savePitchforkLine, 
        "awaitSpawn": awaitSpawn, 
        "awaitGravestoneSpawm": awaitGravestoneSpawm, 
        "awaitGridSpawn": awaitGridSpawn, 
        "awardTime": awardTime, 
        "awardPos": awardPos, 
        "currentCharacterNames": currentCharacterNames, 
    }
    if isSurvival && is_instance_valid(survivalRunner):
        result["survivalPoint"] = survivalRunner.point
        result["survivalRoundNum"] = survivalRunner.roundNum
        result["survivalZombiePool"] = survivalRunner.zombiePool
        result["survivalAddZombiePoolReachId"] = survivalRunner.addZombiePoolReachId
        result["survivalCurrentZombiePool"] = survivalRunner.currentZombiePool
    print("[Save] Feature[Wave]保存完成: currentWave=%d, waveFinal=%s, isRunning=%s, currentCharacter=%d, isSurvival=%s" % [currentWave, waveFinal, isRunning, currentCharacterNames.size(), isSurvival])
    return result

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    print("[Load] 加载Feature[Wave]... (数据项: %d)" % _data.size())
    currentWave = _data.get("currentWave", 0)
    waveFinal = _data.get("waveFinal", false)
    waveStart = _data.get("waveStart", false)
    spawnOver = _data.get("spawnOver", false)
    timer = _data.get("timer", 0.0)
    nextWaveTime = _data.get("nextWaveTime", 0.0)
    isRunning = _data.get("isRunning", false)
    currentSpawnPoint = _data.get("currentSpawnPoint", 0)
    currentHpPointTotal = _data.get("currentHpPointTotal", 0.0)
    currentHpPoint = _data.get("currentHpPoint", 0.0)
    isSurvival = _data.get("isSurvival", false)
    savePitchforkLine = _data.get("savePitchforkLine", -1)
    awaitSpawn = false
    awaitGravestoneSpawm = false
    awaitGridSpawn = false
    if waveFinal && !spawnOver:
        spawnOver = true
    awardTime = _data.get("awardTime", false)
    awardPos = _data.get("awardPos", Vector2.ZERO)
    currentCharacter.clear()
    for characterName: StringName in _data.get("currentCharacterNames", []):
        if _owner.charcterDicionary.has(characterName):
            var character: TowerDefenseCharacter = _owner.charcterDicionary[characterName]
            currentCharacter.append(character)
            if !character.bodyHurt.is_connected(HpPointDecrease):
                character.bodyHurt.connect(HpPointDecrease)
            if !character.armorHurt.is_connected(HpPointDecrease):
                character.armorHurt.connect(HpPointDecrease)
            if !character.destroy.is_connected(CharacterDestroy):
                character.destroy.connect(CharacterDestroy)
    if is_instance_valid(progressFeature) and is_instance_valid(progressFeature.progessManager) and is_instance_valid(progressFeature.progessManager.progressMeter):
        var progressMeter: GeneralProgressMeter = progressFeature.progessManager.progressMeter
        progressMeter.waveNum = config.wave.size()
        progressMeter.waveInterval = config.flagWaveInterval
        progressMeter.FlagRefresh()
        progressMeter.previewWave = currentWave
        if currentHpPointTotal > 0.0:
            progressMeter.progressBar.max_value = currentHpPointTotal
            progressMeter.progressBar.value = currentHpPoint
    if isSurvival && is_instance_valid(survivalRunner) && _data.has("survivalPoint"):
        survivalRunner.point = _data.get("survivalPoint", 0)
        survivalRunner.roundNum = _data.get("survivalRoundNum", 0)
        survivalRunner.zombiePool = _data.get("survivalZombiePool", [])
        survivalRunner.addZombiePoolReachId = _data.get("survivalAddZombiePoolReachId", 0)
        survivalRunner.currentZombiePool = _data.get("survivalCurrentZombiePool", [])
    print("[Load] Feature[Wave]加载完成: currentWave=%d, waveFinal=%s, isRunning=%s, currentCharacter=%d, isSurvival=%s" % [currentWave, waveFinal, isRunning, currentCharacter.size(), isSurvival])
