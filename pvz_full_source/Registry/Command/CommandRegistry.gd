class_name CommandRegistry

static var isInit: bool = false
static var commandDictionary: Dictionary[String, CommandConfig] = {}

static func Init() -> void :
    if isInit:
        return
    isInit = true
    RegisterInit()

static func RegisterInit() -> void :
    BuiltinCommands.Register()
    DebugCommands.Register()

static func RegisterCommand(name: String, description: String, usage: String, callback: Callable, argsInfo: Array = []) -> void :
    var commandName: String = name.to_lower()
    var config: CommandConfig = CommandConfig.new()
    config.name = commandName
    config.description = description
    config.usage = usage
    config.callback = callback
    var typedArgs: Array[CommandArg] = []
    for arg in argsInfo:
        typedArgs.append(arg)
    config.argsInfo = typedArgs
    commandDictionary[commandName] = config

static func UnregisterCommand(name: String) -> void :
    commandDictionary.erase(name.to_lower())

static func HasCommand(name: String) -> bool:
    return commandDictionary.has(name.to_lower())

static func GetCommand(name: String) -> CommandConfig:
    return commandDictionary.get(name.to_lower())

static func GetAllCommands() -> Dictionary[String, CommandConfig]:
    return commandDictionary

static func GetCommandNames() -> Array[String]:
    var names: Array[String] = []
    for key in commandDictionary:
        names.append(key)
    names.sort()
    return names

static func ExecuteCommand(input: String, outputCallback: Callable) -> void :
    var stripped: String = input.strip_edges()
    if stripped == "":
        return
    if !stripped.begins_with("/"):
        outputCallback.call("[color=red]指令必须以 / 开头[/color]")
        return
    var parts: PackedStringArray = _ParseCommand(stripped.substr(1))
    if parts.size() == 0:
        return
    var commandName: String = parts[0].to_lower()
    var args: PackedStringArray = []
    if parts.size() > 1:
        args = parts.slice(1)
    if !commandDictionary.has(commandName):
        outputCallback.call("[color=red]未知指令: /%s  输入 /help 查看所有指令[/color]" % commandName)
        return
    var entry: CommandConfig = commandDictionary[commandName]
    var convertedArgs = _ConvertArgs(args, entry.argsInfo, outputCallback)
    if convertedArgs == null:
        outputCallback.call("[color=red]参数错误！用法: %s[/color]" % entry.usage)
        return
    entry.callback.callv(convertedArgs)

static func _ParseCommand(input: String) -> PackedStringArray:
    var result: PackedStringArray = []
    var current: String = ""
    var inQuotes: bool = false
    for i in range(input.length()):
        var c: String = input[i]
        if c == "\"":
            inQuotes = !inQuotes
        elif c == " " && !inQuotes:
            if current != "":
                result.append(current)
                current = ""
        else:
            current += c
    if current != "":
        result.append(current)
    return result

static func _ConvertArgs(args: PackedStringArray, argsInfo: Array[CommandArg], outputCallback: Callable) -> Variant:
    var result: Array = []
    var argIndex: int = 0
    for info in argsInfo:
        if argIndex >= args.size():
            if info.required:
                return null
            result.append(info.defaultValue)
            continue
        var value: Variant = _ConvertValue(args[argIndex], info.type)
        if value == null:
            outputCallback.call("[color=red]参数 '%s' 类型错误，期望类型: %s[/color]" % [info.name, type_string(info.type)])
            return null
        result.append(value)
        argIndex += 1
    while argIndex < args.size():
        result.append(args[argIndex])
        argIndex += 1
    return result

static func _ConvertValue(value: String, targetType: int) -> Variant:
    match targetType:
        TYPE_STRING:
            return value
        TYPE_INT:
            if value.is_valid_int():
                return value.to_int()
            return null
        TYPE_FLOAT:
            if value.is_valid_float():
                return value.to_float()
            return null
        TYPE_BOOL:
            match value.to_lower():
                "true", "1", "yes", "on":
                    return true
                "false", "0", "no", "off":
                    return false
            return null
    return value
