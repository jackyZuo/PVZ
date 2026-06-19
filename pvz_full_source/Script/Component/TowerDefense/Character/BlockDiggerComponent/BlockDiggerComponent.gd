
class_name BlockDiggerComponent extends ComponentBase


var parent: TowerDefenseCharacter

@export var checkArea: Area2D


func GetName() -> String:
    return "BlockDiggerComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return
    if parent.die:
        return
    if !is_instance_valid(checkArea):
        return
    if checkArea.has_overlapping_areas():
        for area: Area2D in checkArea.get_overlapping_areas():
            var checkCharacter = area.get_parent()
            if checkCharacter is TowerDefenseCharacter:
                if checkCharacter.instance.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND:
                    checkCharacter.BlockDigger(parent)
