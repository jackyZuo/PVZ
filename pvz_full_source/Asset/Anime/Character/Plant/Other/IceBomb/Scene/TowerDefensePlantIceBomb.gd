@tool
extends TowerDefensePlant

func Explode() -> void :
    CreateColdEffect(camp, gridPos)
