@tool
extends TowerDefensePlant

func DestroySet() -> void :
    super.DestroySet()
    CraterCreate()
