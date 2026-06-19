class_name BuiltinCommands

static func Register() -> void :
    CommandRegistry.RegisterCommand("help", "显示所有可用指令", "/help [页码]", 
        _CmdHelp, 
        [CommandArg.new("page", TYPE_INT, false, 1, "页码")])
    CommandRegistry.RegisterCommand("clear", "清空控制台输出", "/clear", 
        _CmdClear)
    CommandRegistry.RegisterCommand("echo", "输出文本到控制台", "/echo <文本>", 
        _CmdEcho, 
        [CommandArg.new("text", TYPE_STRING, true, null, "要输出的文本")])
    CommandRegistry.RegisterCommand("history", "显示指令历史记录", "/history", 
        _CmdHistory)
    CommandRegistry.RegisterCommand("quit", "关闭游戏", "/quit", 
        _CmdQuit)
    CommandRegistry.RegisterCommand("fps", "显示当前帧率", "/fps", 
        _CmdFps)
    CommandRegistry.RegisterCommand("timescale", "设置游戏时间缩放", "/timescale <倍率>", 
        _CmdTimeScale, 
        [CommandArg.new("scale", TYPE_FLOAT, true, null, "时间缩放倍率")])

static func _CmdHelp(page: int = 1) -> void :
    var commands: Array[String] = CommandRegistry.GetCommandNames()
    var pageSize: int = 8
    var totalPages: int = maxi(1, ceili(commands.size() / float(pageSize)))
    page = clampi(page, 1, totalPages)
    CommandConsole.PrintLine("[color=cyan]═══════ 指令列表 (第%d页/共%d页) ═══════[/color]" % [page, totalPages])
    var startIdx: int = (page - 1) * pageSize
    var endIdx: int = mini(startIdx + pageSize, commands.size())
    for i in range(startIdx, endIdx):
        var cmdName: String = commands[i]
        var entry: CommandConfig = CommandRegistry.GetCommand(cmdName)
        CommandConsole.PrintLine("[color=green]/%s[/color] - %s" % [cmdName, entry.description])
        CommandConsole.PrintLine("[color=gray]  用法: %s[/color]" % entry.usage)
    if totalPages > 1:
        CommandConsole.PrintInfo("输入 /help %d 查看下一页" % (page + 1))

static func _CmdClear() -> void :
    CommandConsole.ClearLog()

static func _CmdEcho(text: String) -> void :
    CommandConsole.PrintLine(text)

static func _CmdHistory() -> void :
    var history: Array = CommandConsole.GetHistory()
    if history.size() == 0:
        CommandConsole.PrintInfo("暂无指令历史")
        return
    CommandConsole.PrintLine("[color=cyan]═══════ 指令历史 ═══════[/color]")
    for i in range(history.size()):
        CommandConsole.PrintLine("[color=gray]%d.[/color] %s" % [i + 1, history[i]])

static func _CmdQuit() -> void :
    CommandConsole.PrintWarning("正在退出游戏...")
    (Engine.get_main_loop() as SceneTree).quit()

static func _CmdFps() -> void :
    CommandConsole.PrintInfo("当前FPS: %d" % Engine.get_frames_per_second())

static func _CmdTimeScale(scale: float) -> void :
    Global.timeScale = scale
    CommandConsole.PrintSuccess("时间缩放已设为 %.1fx" % scale)
