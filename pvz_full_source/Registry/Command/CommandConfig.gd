class_name CommandConfig extends Resource

var name: String
var description: String
var usage: String
var callback: Callable
var argsInfo: Array[CommandArg] = []
