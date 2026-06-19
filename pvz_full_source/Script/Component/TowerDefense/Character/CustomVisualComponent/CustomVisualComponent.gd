class_name CustomVisualComponent extends ComponentBase

var parent: TowerDefenseCharacter

func GetName() -> String:
    return "CustomVisualComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func ClearCustom() -> void :
    parent.config.customData.ClearCustomFliters(parent.sprite)

func SetCustom(custom: String) -> void :
    parent.config.customData.SetCustomFliters(parent.sprite, custom)

func SetCustoms(customList: Array[String]) -> void :
    ClearCustom()
    for custom: String in customList:
        if custom != "":
            SetCustom(custom)
