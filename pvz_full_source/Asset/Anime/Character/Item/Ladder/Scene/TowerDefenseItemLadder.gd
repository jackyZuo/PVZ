@tool
extends TowerDefenseItem

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Ladder":
            Destroy()

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    ClearArmorAll()
    Destroy(true)
