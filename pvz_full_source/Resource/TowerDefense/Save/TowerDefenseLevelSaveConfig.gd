class_name TowerDefenseLevelSaveConfig extends Resource

@export var characterList: Array[TowerDefenseCharacterSaveConfig]
@export var projectileList: Array[TowerDefenseProjectileSaveConfig]
@export var dropItemList: Array[TowerDefenseDropItemSaveConfig]
@export var featureSave: Dictionary = {}
@export var processSave: Dictionary = {}
@export var gameStateSave: Dictionary = {}

var charcterDicionary: Dictionary[StringName, TowerDefenseCharacter]
var projectileDicionary: Dictionary[StringName, TowerDefenseProjectile]

func Save() -> void :
    print("[Save] 开始保存关卡数据...")
    characterList.clear()
    for character: TowerDefenseCharacter in Global.get_tree().get_nodes_in_group("Character"):
        if character.isShow:
            continue
        if !character.inGame:
            continue
        if character.die:
            continue
        if character.instance.die:
            continue
        var characterSaveConfig: TowerDefenseCharacterSaveConfig = TowerDefenseCharacterSaveConfig.new()
        characterSaveConfig.SaveCharacter(character)
        characterList.append(characterSaveConfig)
    print("[Save] 保存角色数量: %d" % characterList.size())
    projectileList.clear()
    for projectile: TowerDefenseProjectile in Global.get_tree().get_nodes_in_group("Projectile"):
        if projectile.over:
            continue
        var projectileSaveConfig: TowerDefenseProjectileSaveConfig = TowerDefenseProjectileSaveConfig.new()
        projectileSaveConfig.SaveProjectile(projectile)
        projectileList.append(projectileSaveConfig)
    print("[Save] 保存投射物数量: %d" % projectileList.size())
    dropItemList.clear()
    for sun: TowerDefenseSunBase in Global.get_tree().get_nodes_in_group("Sun"):
        if sun.die or sun.isCollect:
            continue
        var dropItemSaveConfig: TowerDefenseDropItemSaveConfig = TowerDefenseDropItemSaveConfig.new()
        dropItemSaveConfig.SaveDropItem(sun)
        dropItemList.append(dropItemSaveConfig)
    print("[Save] 保存掉落物数量: %d" % dropItemList.size())
    featureSave.clear()
    processSave.clear()
    var control: TowerDefenseControlNew = TowerDefenseManager.currentControl
    if is_instance_valid(control):
        for featureName: StringName in control.featureDictionary:
            var feature: TowerDefenseBattleFeature = control.featureDictionary[featureName]
            var data: Dictionary = feature.SaveFeature()
            if data.size() > 0:
                featureSave[featureName] = data
                print("[Save] 保存Feature: %s (数据项: %d)" % [featureName, data.size()])
        if is_instance_valid(control.process):
            var processData: Dictionary = control.process.SaveProcess()
            if processData.size() > 0:
                processSave["main"] = processData
                print("[Save] 保存Process: %s (数据项: %d)" % [control.process.get_script().get_global_name(), processData.size()])
    gameStateSave = {
        "runGameTime": TowerDefenseManager.runGameTime, 
        "timeScale": Global.timeScale, 
        "pausePacket": TowerDefenseManager.pausePacket, 
        "pauseZombie": TowerDefenseManager.pauseZombie, 
    }
    print("[Save] 保存游戏状态: runGameTime=%.2f, timeScale=%.2f, pausePacket=%s, pauseZombie=%s" % [TowerDefenseManager.runGameTime, Global.timeScale, TowerDefenseManager.pausePacket, TowerDefenseManager.pauseZombie])
    print("[Save] 关卡数据保存完成")

func Load() -> void :
    print("[Load] 开始加载关卡数据...")
    print("[Load] 加载角色数量: %d" % characterList.size())
    print("[Load] featureSave.size()=%d, processSave.size()=%d, gameStateSave.size()=%d" % [featureSave.size(), processSave.size(), gameStateSave.size()])
    print("[Load] featureSave keys: %s" % str(featureSave.keys()))
    print("[Load] processSave keys: %s" % str(processSave.keys()))
    charcterDicionary.clear()
    projectileDicionary.clear()
    for characterSaveConfig: TowerDefenseCharacterSaveConfig in characterList:
        characterSaveConfig.owner = self
        var character: TowerDefenseCharacter = characterSaveConfig.LoadCharacter()
        charcterDicionary[characterSaveConfig.nodeName] = character
        print("[Load] 加载角色: %s (%s)" % [characterSaveConfig.nodeName, characterSaveConfig.packetName])
    for projectileSaveConfig: TowerDefenseProjectileSaveConfig in projectileList:
        var projectile: TowerDefenseProjectile = projectileSaveConfig.LoadProjectile(self)
        projectileDicionary[projectileSaveConfig.nodeName] = projectile
        print("[Load] 加载投射物: %s (%s)" % [projectileSaveConfig.nodeName, projectileSaveConfig.configName])
    for dropItemSaveConfig: TowerDefenseDropItemSaveConfig in dropItemList:
        dropItemSaveConfig.LoadDropItem(self)
        print("[Load] 加载掉落物: type=%d pos=(%.1f, %.1f)" % [dropItemSaveConfig.dropItemType, dropItemSaveConfig.pos.x, dropItemSaveConfig.pos.y])
    var control: TowerDefenseControlNew = TowerDefenseManager.currentControl
    if is_instance_valid(control):
        print("[Load] control.featureDictionary keys: %s" % str(control.featureDictionary.keys()))
        for featureName: String in featureSave:
            if !control.featureDictionary.has(StringName(featureName)):
                control.AddFeature(StringName(featureName), {})
            if control.featureDictionary.has(StringName(featureName)):
                control.featureDictionary[StringName(featureName)].LoadFeature(featureSave[featureName], self)
                print("[Load] 加载Feature: %s (数据项: %d)" % [featureName, featureSave[featureName].size()])
        if is_instance_valid(control.process) and processSave.has("main"):
            control.process.LoadProcess(processSave["main"], self)
            print("[Load] 加载Process: %s (数据项: %d)" % [control.process.get_script().get_global_name(), processSave["main"].size()])
        else:
            print("[Load] Process未加载: process有效=%s, processSave.has('main')=%s" % [is_instance_valid(control.process), processSave.has("main")])
    else:
        print("[Load] control无效，无法加载Feature和Process")
    TowerDefenseManager.runGameTime = gameStateSave.get("runGameTime", 0.0)
    Global.timeScale = gameStateSave.get("timeScale", 1.0)
    TowerDefenseManager.pausePacket = gameStateSave.get("pausePacket", false)
    TowerDefenseManager.pauseZombie = gameStateSave.get("pauseZombie", false)
    print("[Load] 加载游戏状态: runGameTime=%.2f, timeScale=%.2f, pausePacket=%s, pauseZombie=%s" % [TowerDefenseManager.runGameTime, Global.timeScale, TowerDefenseManager.pausePacket, TowerDefenseManager.pauseZombie])
    print("[Load] 关卡数据加载完成")
