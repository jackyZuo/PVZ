class_name CommandArg extends Resource

var name: String
var type: int = TYPE_STRING
var required: bool = true
var defaultValue: Variant = null
var description: String = ""

var suggestions: Callable

func _init(_name: String = "", _type: int = TYPE_STRING, _required: bool = true, _defaultValue: Variant = null, _description: String = "", _suggestions: Callable = Callable()) -> void :
    name = _name
    type = _type
    required = _required
    defaultValue = _defaultValue
    description = _description
    suggestions = _suggestions
