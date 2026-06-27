class_name DebugCommands

static func Register() -> void :
    CommandRegistry.RegisterCommand("sun", "设置阳光数量", "/sun <数量>", 
        func(value: int): TowerDefenseManager.SetSun(value), 
        [CommandArg.new("value", TYPE_INT, true, null, "阳光数量")])
    CommandRegistry.RegisterCommand("coin", "设置金币数量", "/coin <数量>", 
        func(value: int): TowerDefenseManager.coinBank.num = value, 
        [CommandArg.new("value", TYPE_INT, true, null, "金币数量")])
    CommandRegistry.RegisterCommand("crystal", "设置水晶数量", "/crystal <数量>", 
        func(value: int): GameSaveManager.SetKeyValue("CrystalNum", value);GameSaveManager.Save(), 
        [CommandArg.new("value", TYPE_INT, true, null, "水晶数量")])
    CommandRegistry.RegisterCommand("killall", "秒杀所有僵尸", "/killall", 
        _CmdKillAll)
    CommandRegistry.RegisterCommand("win", "直接胜利", "/win", 
        _CmdInstantWin)
    CommandRegistry.RegisterCommand("skipwave", "跳过等待下一波", "/skipwave", 
        _CmdSkipWaveWait)
    CommandRegistry.RegisterCommand("skipfinal", "跳到最终波", "/skipfinal", 
        _CmdSkipToFinalWave)
    CommandRegistry.RegisterCommand("skipto", "跳到指定波次", "/skipto <波次>", 
        _CmdSkipToWave, 
        [CommandArg.new("wave", TYPE_INT, true, null, "目标波次")])
    CommandRegistry.RegisterCommand("restoremower", "恢复所有割草机", "/restoremower", 
        _CmdRestoreAllMowers)
    CommandRegistry.RegisterCommand("removemower", "移除所有割草机", "/removemower", 
        _CmdRemoveAllMowers)
    CommandRegistry.RegisterCommand("resetbrain", "重置所有脑子", "/resetbrain", 
        _CmdResetAllBrains)
    CommandRegistry.RegisterCommand("debug", "切换调试选项", "/debug <选项名> [on/off]", 
        _CmdDebug, 
        [CommandArg.new("option", TYPE_STRING, true, null, "选项名"), 
            CommandArg.new("value", TYPE_STRING, false, "toggle", "on/off")])
    CommandRegistry.RegisterCommand("debuglist", "列出所有调试选项", "/debuglist", 
        _CmdDebugList)

static func _GetTree() -> SceneTree:
    return Engine.get_main_loop() as SceneTree

static func _CmdKillAll() -> void :
    for zombie in _GetTree().get_nodes_in_group("Zombie"):
        if is_instance_valid(zombie) && zombie is TowerDefenseZombie:
            if !zombie.instance.die:
                zombie.Hurt(1000000000000)
    CommandConsole.PrintSuccess("已秒杀所有僵尸")

static func _CmdInstantWin() -> void :
    _CmdKillAll()
    var wave = TowerDefenseBattleProcessWave.instance
    if !wave:
        CommandConsole.PrintError("当前不在战斗中")
        return
    wave.waveStart = true
    wave.waveFinal = true
    wave.final.emit()
    wave.awaitSpawn = false
    CommandConsole.PrintSuccess("已直接胜利")

static func _CmdSkipWaveWait() -> void :
    var wave = TowerDefenseBattleProcessWave.instance
    if !wave:
        CommandConsole.PrintError("当前不在战斗中")
        return
    wave.timer = wave.nextWaveTime
    wave.awaitSpawn = false
    CommandConsole.PrintSuccess("已跳过等待")

static func _CmdSkipToFinalWave() -> void :
    var wave = TowerDefenseBattleProcessWave.instance
    if !wave:
        CommandConsole.PrintError("当前不在战斗中")
        return
    if !wave.waveStart:
        wave.waveStart = true
    while !wave.waveFinal:
        wave.timer = wave.nextWaveTime
        wave.awaitSpawn = false
        await _GetTree().create_timer(0.2, false).timeout
    CommandConsole.PrintSuccess("已跳到最终波")

static func _CmdSkipToWave(targetWave: int) -> void :
    var wave = TowerDefenseBattleProcessWave.instance
    if !wave:
        CommandConsole.PrintError("当前不在战斗中")
        return
    while wave.currentWave < targetWave && !wave.waveFinal:
        wave.timer = wave.nextWaveTime
        wave.awaitSpawn = false
        await _GetTree().create_timer(0.2, false).timeout
    CommandConsole.PrintSuccess("已跳到第 %d 波" % targetWave)

static func _CmdRestoreAllMowers() -> void :
    var currentControl = TowerDefenseManager.currentControl
    var mowerFeature: TowerDefenseBattleFeatureMower = currentControl.GetFeature("Mower")
    if !mowerFeature:
        CommandConsole.PrintError("当前场景没有割草机")
        return
    var mapFeature = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            if !is_instance_valid(mowerFeature.mowerLine[line]):
                mowerFeature.CreateMower(line)
    CommandConsole.PrintSuccess("已恢复所有割草机")

static func _CmdRemoveAllMowers() -> void :
    var currentControl = TowerDefenseManager.currentControl
    var mowerFeature: TowerDefenseBattleFeatureMower = currentControl.GetFeature("Mower")
    if !mowerFeature:
        CommandConsole.PrintError("当前场景没有割草机")
        return
    for line in range(mowerFeature.mowerLine.size()):
        if is_instance_valid(mowerFeature.mowerLine[line]):
            mowerFeature.mowerLine[line].queue_free()
            mowerFeature.mowerLine[line] = null
    CommandConsole.PrintSuccess("已移除所有割草机")

static func _CmdResetAllBrains() -> void :
    var currentControl = TowerDefenseManager.currentControl
    var brainFeature: TowerDefenseBattleFeatureBrain = currentControl.GetFeature("Brain")
    if !brainFeature:
        CommandConsole.PrintError("当前场景没有脑子")
        return
    var mapFeature = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(brainFeature.brainLine.size()):
        if is_instance_valid(brainFeature.brainLine[line]):
            brainFeature.brainLine[line].queue_free()
            brainFeature.brainLine[line] = null
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            brainFeature.CreateBrain(line)
    CommandConsole.PrintSuccess("已重置所有脑子")

static func _CmdDebug(option: String, value: String = "toggle") -> void :
    var debugVars: Dictionary = {
        "openalllevel": "debugOpenAllLevel", 
        "coinmax": "debugCoinMax", 
        "sunmax": "debugSunMax", 
        "packetselect": "debugPacketSelect", 
        "packetopenall": "debugPacketOpenAll", 
        "packetcolddown": "debugPacketColdDown", 
        "openallcustom": "debugOpenAllCustom", 
        "openglove": "debugOpenGlove", 
        "unlimitedfire": "debugUnlimitedFire", 
        "plantinvincible": "debugPlantInvincible", 
        "nolose": "debugNoLose", 
        "wavepaused": "debugWavePaused", 
        "nozombiespawn": "debugNoZombieSpawn", 
        "braininvincible": "debugBrainInvincible",
        "vasexray": "debugVaseXRay",
    }
    var key: String = option.to_lower()
    if !debugVars.has(key):
        CommandConsole.PrintError("未知调试选项: %s  输入 /debuglist 查看所有选项" % option)
        return
    var varName: String = debugVars[key]
    match value.to_lower():
        "on", "true", "1":
            CommandManager.set(varName, true)
        "off", "false", "0":
            CommandManager.set(varName, false)
        _:
            CommandManager.set(varName, !CommandManager.get(varName))
    var newState: bool = CommandManager.get(varName)
    CommandConsole.PrintSuccess("%s -> %s" % [key, "开启" if newState else "关闭"])

static func _CmdDebugList() -> void :
    var debugVars: Array = [
        ["openalllevel", "开启所有关卡"], 
        ["coinmax", "满金币"], 
        ["sunmax", "满阳光"], 
        ["packetselect", "任何模式启用选卡"], 
        ["packetopenall", "解锁所有卡牌"], 
        ["packetcolddown", "卡牌无冷却"], 
        ["openallcustom", "开启所有装扮"], 
        ["openglove", "启用手套"], 
        ["unlimitedfire", "无限火力"], 
        ["plantinvincible", "植物无敌"], 
        ["nolose", "禁用失败"], 
        ["wavepaused", "暂停波次"], 
        ["nozombiespawn", "禁止僵尸生成"], 
        ["braininvincible", "脑子无敌"],
        ["vasexray", "开罐子透视"],
    ]
    CommandConsole.PrintLine("[color=cyan]═══════ 调试选项列表 ═══════[/color]")
    for item in debugVars:
        var varName: String = "debug" + item[0].capitalize().replace(" ", "")
        var currentState: bool = CommandManager.get(varName)
        var stateStr: String = "[color=green]ON[/color]" if currentState else "[color=red]OFF[/color]"
        CommandConsole.PrintLine("[color=green]/debug %s[/color] %s - %s" % [item[0], stateStr, item[1]])
