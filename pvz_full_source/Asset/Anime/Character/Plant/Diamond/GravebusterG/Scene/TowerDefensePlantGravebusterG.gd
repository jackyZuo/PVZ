@tool
extends TowerDefensePlant

func Over(_graveStone: TowerDefenseGravestone) -> void :
    if is_instance_valid(cell):
        cell.Clear()
        CraterCreate(true, "CraterG")
