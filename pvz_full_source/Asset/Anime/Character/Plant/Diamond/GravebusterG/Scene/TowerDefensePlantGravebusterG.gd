@tool
extends TowerDefensePlant

func Over() -> void :
    if is_instance_valid(cell):
        cell.Clear()
        CraterCreate(true, "CraterG")
