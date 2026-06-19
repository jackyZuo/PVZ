class_name SunDropItemHandler extends DropItemHandler

@warning_ignore("unused_parameter")
func OnCollect(pos: Vector2, value: int) -> void :
    TowerDefenseManager.AddSun(value)
