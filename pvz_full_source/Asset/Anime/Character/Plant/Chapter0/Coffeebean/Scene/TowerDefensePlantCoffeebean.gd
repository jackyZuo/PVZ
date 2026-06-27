@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(cell):
        for character in cell.characterList:
            if character.camp == camp:
                character.WakeUp()
