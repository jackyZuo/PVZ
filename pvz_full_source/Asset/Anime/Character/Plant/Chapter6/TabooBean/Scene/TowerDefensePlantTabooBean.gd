@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(cell):
        for character in cell.characterList:
            if !(character is TowerDefensePlant):
                continue
            if character.camp != camp:
                continue
            character.WakeUp()
            character.BuffAdd(TowerDefenseCharacterBuffTabooBean.new())
