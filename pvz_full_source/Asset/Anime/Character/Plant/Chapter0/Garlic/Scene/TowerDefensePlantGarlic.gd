@tool
extends TowerDefensePlant

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.invincibleHurt = true

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        if character.instance.ArmorHas("SpecialHelmet"):
            SkipInvincibleHurt(num)
            return
    match type:
        "Eat":
            SkipInvincibleHurt(max(10.0, num))
            if is_instance_valid(character):
                character.Garlic()
        "Smash":
            Destroy()
        "Chomp":
            Destroy()
