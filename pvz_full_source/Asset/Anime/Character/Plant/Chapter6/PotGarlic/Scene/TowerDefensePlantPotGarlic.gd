@tool
extends TowerDefensePlant

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    instance.invincibleHurt = true

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        if character.instance.ArmorHas("SpecialHelmet"):
            SkipInvincibleHurt(num)
            return
    match type:
        "Eat":
            SkipInvincibleHurt(10)
            character.Garlic()
        "Smash":
            Destroy()
        "Chomp":
            Destroy()
