
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
    parent.sprite.material.set("shader_parameter/brightStrength", init)
    brightTween = parent.create_tween()
    if delay > 0.0:
        brightTween.tween_interval(delay)
    if riseDuration > 0.0:
        brightTween.tween_property(parent.sprite.material, "shader_parameter/brightStrength", rise, riseDuration).from(init)
    brightTween.tween_property(parent.sprite.material, "shader_parameter/brightStrength", 0, duration).from(rise)





func White(init: float = 1.0, delay: float = 0.0, duration: float = 0.5) -> void :
    if is_instance_valid(whiteTween) && whiteTween.is_running():
        whiteTween.kill()
    parent.sprite.material.set("shader_parameter/whiteStrength", init)
    whiteTween = parent.create_tween()
    if delay > 0.0:
        whiteTween.tween_interval(delay)
    whiteTween.tween_property(parent.sprite.material, "shader_parameter/whiteStrength", 0, duration).from(init)
