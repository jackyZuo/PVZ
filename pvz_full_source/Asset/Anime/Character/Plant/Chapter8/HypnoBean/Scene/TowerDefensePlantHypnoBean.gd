@tool
extends TowerDefensePlant

func Explode() -> void :
    if is_instance_valid(targetZombie):
        if targetZombie.camp != camp:
            if !(targetZombie.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES) && !targetZombie.instance.ArmorHas("SpecialHelmet"):
                BrainSunCreate(targetZombie.global_position, 100)
            targetZombie.Hypnoses()
    if is_instance_valid(cell):
        var plantList: Array[TowerDefensePlant] = []
        for character in cell.characterList:
            if character.camp != camp:
                plantList.append(character)
        if plantList.size() >= 1:
            plantList[0].Hypnoses()
