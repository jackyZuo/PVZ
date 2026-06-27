@tool
class_name TowerDefenseGravestone extends TowerDefenseCharacter

@export var rise: bool = true
@export var canBeAttacked: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    instance.hitpointsEmpty.connect(Destroy)
    add_to_group("Gravestone", true)
    if rise:
        if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
            rise = false
        else:
            Rise(randf_range(0.75, 1.25))


@warning_ignore("unused_parameter")
func BlowBack(num: float, time: float = 1.0) -> void :
    pass
