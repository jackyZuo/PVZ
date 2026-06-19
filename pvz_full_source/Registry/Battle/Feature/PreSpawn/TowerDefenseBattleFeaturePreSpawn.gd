class_name TowerDefenseBattleFeaturePreSpawn extends TowerDefenseBattleFeature

var config: TowerDefenseBattleFeaturePreSpawnConfig

var preSpawnList: Array[TowerDefenseCharacter]

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseBattleFeaturePreSpawnConfig.new()
    config.Init(data)

func GameEntry() -> void :
    if control.hasProgress:
        return
    if !control.isInit:
        return
    var levelConfig: TowerDefenseLevelConfig = control.levelConfig
    if levelConfig.finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM && levelConfig._IZMManager.shuffle:
        var izmProcess = control.process as TowerDefenseBattleProcessIZM
        if izmProcess:
            preSpawnList.append_array(izmProcess.Execute(config.preSpawnList))
            return
    var recheckList: Array = []
    for preSpawn: TowerDefenseLevelPreSpawnConfig in config.preSpawnList:
        var characterSpawn = preSpawn.SpawnCharacter()
        if !is_instance_valid(characterSpawn):
            recheckList.append(preSpawn)
        else:
            preSpawnList.append(characterSpawn)
            if is_instance_valid(preSpawn.characterOverride):
                preSpawn.characterOverride.ExecuteCharacter(characterSpawn)
    for preSpawn: TowerDefenseLevelPreSpawnConfig in recheckList:
        var characterSpawn = preSpawn.SpawnCharacter()
        if is_instance_valid(characterSpawn):
            preSpawnList.append(characterSpawn)
            if is_instance_valid(preSpawn.characterOverride):
                preSpawn.characterOverride.ExecuteCharacter(characterSpawn)

func GameStart() -> void :
    for character: TowerDefenseCharacter in preSpawnList:
        if is_instance_valid(character):
            character.call("PreSpawn")
            if character is TowerDefensePlant:
                if character.CanSleep():
                    character.Sleep.call_deferred()
                else:
                    character.Idle.call_deferred()
            if character is TowerDefenseZombie:
                character.Walk.call_deferred()
    preSpawnList.clear()
