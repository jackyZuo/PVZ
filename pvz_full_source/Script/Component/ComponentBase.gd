
class_name ComponentBase extends Node2D

func _enter_tree() -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        process_mode = Node.PROCESS_MODE_DISABLED


@export var alive: bool = true: set = SetAlive


func GetName() -> String:
    return ""

func ExportComponentSave() -> Dictionary:
    return {}

@warning_ignore("unused_parameter")
func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    pass



func SetAlive(_alive: bool) -> void :
    alive = _alive
