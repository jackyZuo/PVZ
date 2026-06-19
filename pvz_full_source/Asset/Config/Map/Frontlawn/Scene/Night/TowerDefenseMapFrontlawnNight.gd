extends TowerDefenseMap

@onready var frontlawnFloor: Sprite2D = %FrontlawnFloor
@onready var frontlawnDoor: Sprite2D = %FrontlawnDoor

func EnterRoom(character: TowerDefenseCharacter) -> void :
    var duration: float = maxf(abs(global_position.y - 375.0) / 200.0, 0.01)
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(character, ^"global_position:y", 375.0, duration)
    tween.tween_property(character, ^"shadowComponent:saveShadowPosition:y", 375.0 + 36.0, duration)
    await tween.finished
    if is_instance_valid(character):
        character.timeScaleInit *= 2
    frontlawnDoor.visible = true
    frontlawnFloor.visible = true
    await get_tree().create_timer(3.0, false).timeout
