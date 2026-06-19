class_name JalapenoSunDropItemHandler extends DropItemHandler

var gridPos: Vector2i = Vector2i.ZERO

@warning_ignore("unused_parameter")
func OnCollect(pos: Vector2, value: int) -> void :
    TowerDefenseManager.AddSun(value)

func ShouldAutoCollect() -> bool:
    return TowerDefenseManager.IsIZMMode()

func Reset() -> void :
    gridPos = Vector2i.ZERO
