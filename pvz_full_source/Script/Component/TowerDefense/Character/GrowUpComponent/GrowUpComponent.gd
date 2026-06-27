
class_name GrowUpComponent extends ComponentBase


@export var growUpTime: Array[float] = []

@export var growUpSize: Array[float] = []


signal grow(reach: int)


var parent: TowerDefenseCharacter


var timer: float = 0.0

var growUpReach: int = 0


func GetName() -> String:
    return "GrowUpComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    await get_tree().physics_frame
    if TowerDefenseManager.IsIZMMode():
        parent.transformPoint.scale = Vector2.ONE * growUpSize[growUpTime.size() - 1]
        growUpReach = growUpTime.size() - 1
        grow.emit(growUpTime.size() - 1)
        growUpReach = growUpTime.size()


func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return
    if parent.die:
        return
    if parent.instance.sleep:
        return
    if !parent.componentAlive:
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if growUpReach < growUpTime.size():
        timer += delta
        if timer > growUpTime[growUpReach]:
            grow.emit(growUpReach)
            AudioManager.AudioPlay("Grow", AudioManagerEnum.TYPE.SFX)
            var tween = create_tween()
            tween.set_parallel(true)
            tween.tween_property(parent.transformPoint, "scale", Vector2.ONE * growUpSize[growUpReach], 1.0)
            growUpReach += 1

func ExportComponentSave() -> Dictionary:
    return {
        "timer": timer, 
        "growUpReach": growUpReach, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
    growUpReach = _data.get("growUpReach", 0)
