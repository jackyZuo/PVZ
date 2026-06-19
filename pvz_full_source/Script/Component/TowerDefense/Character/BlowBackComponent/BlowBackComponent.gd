
class_name BlowBackComponent extends ComponentBase


var parent: TowerDefenseCharacter


var blowBack: bool = false

var blowBackNum: float = 0.0

var _blowBackTweens: int = 0


func GetName() -> String:
    return "BlowBackComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready




func BlowBack(num: float, time: float = 1.0) -> void :
    if parent.instance.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND:
        return
    if parent.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.BLOW:
        return
    if parent is TowerDefensePlant:
        return
    if time > 0.0:
        var blowValue: float = TowerDefenseManager.GetMapGridSize().x * num / time
        _blowBackTweens += 1
        blowBack = true
        blowBackNum += blowValue
        await parent.get_tree().create_timer(time, false).timeout
        blowBackNum -= blowValue
        _blowBackTweens -= 1
        if _blowBackTweens <= 0:
            blowBack = false
            _blowBackTweens = 0
    else:
        parent.global_position.x += TowerDefenseManager.GetMapGridSize().x * num
