class_name EnvironmentAnimeComponent extends ComponentBase

var parent: TowerDefenseCharacter
var timer: float = 0.0

func GetName() -> String:
    return "EnvironmentAnimeComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func SetFrame(isNight: bool, isWater: bool) -> void :
    if isNight:
        if isWater:
            parent.sprite.SetAnimation("WaterNight")
        else:
            parent.sprite.SetAnimation("Night")
    else:
        if isWater:
            parent.sprite.SetAnimation("Water")
        else:
            parent.sprite.SetAnimation("Day")

func WaterBob(_timer: float, timeScale: float) -> float:
    timer += get_physics_process_delta_time() * timeScale
    parent.sprite.position.y = sin(timer * 2.0) * 2.0
    return timer

func ExportComponentSave() -> Dictionary:
    return {
        "timer": timer, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
