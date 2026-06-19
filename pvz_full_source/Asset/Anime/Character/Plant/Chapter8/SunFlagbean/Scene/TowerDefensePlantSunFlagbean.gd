@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(cell):
        var characterList: Array[TowerDefenseCharacter] = cell.GetCharacterList()
        for character in characterList:
            if is_instance_valid(character):
                character.WeakUp()
    if instance.hypnoses:
        BrainSunCreate(global_position, 200)
    else:
        SunCreate(global_position, 200)
    if is_instance_valid(TowerDefenseBattleProcessWave.instance) && is_instance_valid(TowerDefenseBattleProcessWave.instance.config) && !TowerDefenseBattleProcessWave.instance.waveFinal:
        TowerDefenseBattleProcessWave.instance.NextWave()
