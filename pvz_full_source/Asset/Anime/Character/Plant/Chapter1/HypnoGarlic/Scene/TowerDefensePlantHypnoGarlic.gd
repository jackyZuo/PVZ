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
        if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES:
            SkipInvincibleHurt(num)
            return
    match type:
        "Eat":
            SkipInvincibleHurt(max(10.0, num))
            if is_instance_valid(character):
                character.Garlic()
                if !IsSleep():
                    character.Hypnoses()
        "Smash":
            Destroy()
        "Chomp":
            Destroy()
