
class_name FireComponentExtendBase extends ComponentBase


@export var preExtend: FireComponentExtendBase


var parent: TowerDefenseCharacter


func GetName() -> String:
    return "FireComponentExtendBase"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return



func CanRun() -> bool:
    if is_instance_valid(preExtend):
        return preExtend.CanRun()
    return true
