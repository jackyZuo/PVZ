
class_name HitFlashComponent extends ComponentBase


var parent: TowerDefenseCharacter


var brightTween: Tween

var whiteTween: Tween


func GetName() -> String:
    return "HitFlashComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready







func Bright(init: float = 0.5, delay: float = 0.0, rise: float = 0.5, riseDuration: float = 0.0, duration: float = 0.2) -> void :
    if is_instance_valid(brightTween) && brightTween.is_running():
        brightTween.kill()
    parent.sprite.set_instance_shader_parameter("brightStrength", init)
    brightTween = parent.create_tween()
    if delay > 0.0:
        brightTween.tween_interval(delay)
    if riseDuration > 0.0:
        brightTween.tween_method(_set_bright_strength, init, rise, riseDuration)
    brightTween.tween_method(_set_bright_strength, rise, 0.0, duration)





func White(init: float = 1.0, delay: float = 0.0, duration: float = 0.5) -> void :
    if is_instance_valid(whiteTween) && whiteTween.is_running():
        whiteTween.kill()
    parent.sprite.set_instance_shader_parameter("whiteStrength", init)
    whiteTween = parent.create_tween()
    if delay > 0.0:
        whiteTween.tween_interval(delay)
    whiteTween.tween_method(_set_white_strength, init, 0.0, duration)

func _set_bright_strength(value: float) -> void :
    if is_instance_valid(parent) && is_instance_valid(parent.sprite):
        parent.sprite.set_instance_shader_parameter("brightStrength", value)

func _set_white_strength(value: float) -> void :
    if is_instance_valid(parent) && is_instance_valid(parent.sprite):
        parent.sprite.set_instance_shader_parameter("whiteStrength", value)
