class_name BrainSunDropItemHandler extends DropItemHandler

func GetCollectValue(baseValue: int) -> int:
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        return baseValue
    return - baseValue

@warning_ignore("unused_parameter")
func OnCollect(pos: Vector2, value: int) -> void :
    if value > 0:
        TowerDefenseManager.AddSun(value)
    else:
        TowerDefenseManager.UseSun( - value)
