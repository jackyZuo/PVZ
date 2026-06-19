class_name PuzzleShaderComponent extends ComponentBase

var parent: TowerDefensePlant

func GetName() -> String:
    return "PuzzleShaderComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func Init() -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        if is_instance_valid(LevelEditorInformationEditor.instance.levelConfig):
            if LevelEditorInformationEditor.instance.levelConfig.finishMethod == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
                parent.SetSpriteGroupShaderParameter("puzzle", true)
    else:
        if TowerDefenseManager.GetGameMethod() == TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            parent.SetSpriteGroupShaderParameter("puzzle", true)

func IdleEntered() -> void :
    if TowerDefenseManager.IsIZMMode():
        parent.timeScaleSave = parent.timeScaleInit
        parent.timeScaleInit = 0.0
        parent.timeScale = 0.0
        parent.sprite.timeScale = 0.0

func IdleExited() -> void :
    if TowerDefenseManager.IsIZMMode():
        parent.timeScaleInit = parent.timeScaleSave
