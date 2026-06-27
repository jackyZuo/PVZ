@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(cell):
        var characterList: Array[TowerDefenseCharacter] = cell.GetCharacterList()
        for character in characterList:
            if is_instance_valid(character):
                character.WakeUp()
    if instance.hypnoses:
        BrainSunCreate(global_position, 200)
    else:
        SunCreate(global_position, 200)
    if is_instance_valid(TowerDefenseBattleFeatureWave.instance) && is_instance_valid(TowerDefenseBattleFeatureWave.instance.config) && !TowerDefenseBattleFeatureWave.instance.waveFinal:
        TowerDefenseBattleFeatureWave.instance.NextWave()
