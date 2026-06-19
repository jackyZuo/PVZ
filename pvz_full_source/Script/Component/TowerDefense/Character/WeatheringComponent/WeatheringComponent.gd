class_name WeatheringComponent extends ComponentBase

var parent: TowerDefenseCrater

func GetName() -> String:
    return "WeatheringComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func Processing(delta: float) -> void :
    parent.dieDownTimer += delta
    if parent.config is TowerDefenseCraterConfig:
        if parent.dieDownTimer > parent.config.dieDownTime / parent.stageMax * (parent.stage + 1):
            parent.stage += 1
            if parent.stage < parent.stageMax:
                parent.SetFliter(parent.stage)
            else:
                parent.DieDown()
