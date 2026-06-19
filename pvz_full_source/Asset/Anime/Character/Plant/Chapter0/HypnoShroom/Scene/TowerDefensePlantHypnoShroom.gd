@tool
extends TowerDefensePlant

var over: bool = false

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if instance.sleep:
        return
    if over:
        return
    if is_instance_valid(character):
        if character.instance.ArmorHas("SpecialHelmet"):
            SkipInvincibleHurt(num)
            return
    if type == "Eat":
        over = true
        if is_instance_valid(character):
            character.Hypnoses()
        Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
