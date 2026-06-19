@tool
extends TowerDefensePlant

func Drag(character: TowerDefenseCharacter, success: bool) -> void :
    if !success:
        return
    if !is_instance_valid(character):
        return
    var tween = character.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_parallel(true)
    tween.tween_property(character.transformPoint, ^"scale", Vector2.ONE, 0.5).from(Vector2.ONE * 0.5)
    character.Hypnoses()
    character.global_position.x = global_position.x

    if !instance.hypnoses && !character.instance.hypnoses:
        character.Destroy()
