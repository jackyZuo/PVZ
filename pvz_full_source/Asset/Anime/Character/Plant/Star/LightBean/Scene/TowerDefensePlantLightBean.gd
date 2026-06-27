@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(cell):
        for character in cell.characterList:
            if character.camp != camp:
                continue
            var buffFluorescence: TowerDefenseCharacterBuffFluorescence = TowerDefenseCharacterBuffFluorescence.new()
            buffFluorescence.time = 50
            character.BuffAdd(buffFluorescence)
            character.WakeUp()
