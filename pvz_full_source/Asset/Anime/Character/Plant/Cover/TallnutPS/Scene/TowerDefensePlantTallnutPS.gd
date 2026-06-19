@tool
extends TowerDefensePlant

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        if type != "Eat":
            character.Hurt(min(1000.0, num), false)
        else:
            character.Hurt(min(80, num / 3.0), false)
