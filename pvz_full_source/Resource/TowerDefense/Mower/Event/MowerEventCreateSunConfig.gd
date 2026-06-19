class_name MowerEventCreateSunConfig extends MowerEventConfig

@export var num: int = 25

@warning_ignore("unused_parameter")
func Execute(character: TowerDefenseCharacter):
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        character.BrainSunCreate(character.global_position, num, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
    else:
        character.SunCreate(character.global_position, num, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
