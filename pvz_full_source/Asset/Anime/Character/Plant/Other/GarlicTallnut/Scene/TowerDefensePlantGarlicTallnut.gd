@tool
extends TowerDefensePlant

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

var over: bool = false

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage1":
            explodeComponent.Explode()
        "Damage2":
            explodeComponent.Explode()

func DestroySet() -> void :
    if over:
        return
    over = true
    explodeComponent.Explode()

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        if character.instance.ArmorHas("SpecialHelmet"):
            SkipInvincibleHurt(num)
            return
    match type:
        "Eat":
            SkipInvincibleHurt(max(40.0, num))
            character.Garlic()

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
