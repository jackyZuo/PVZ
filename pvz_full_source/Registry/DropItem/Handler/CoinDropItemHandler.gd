class_name CoinDropItemHandler extends DropItemHandler

@warning_ignore("unused_parameter")
func OnCollect(pos: Vector2, value: int) -> void :
    TowerDefenseManager.AddCoin(value)
