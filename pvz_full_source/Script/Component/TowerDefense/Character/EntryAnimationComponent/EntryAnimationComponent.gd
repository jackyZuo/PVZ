class_name EntryAnimationComponent extends ComponentBase

var parent: TowerDefenseCharacter

func GetName() -> String:
    return "EntryAnimationComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func PlayFallBounce(fallZ: float = 900.0, fallDelay: float = 0.0, fallDuration: float = 0.25) -> void :
    parent.isGround = false
    parent.z = fallZ
    if fallDelay > 0.0:
        await parent.get_tree().create_timer(fallDelay, false).timeout
    var tween = parent.create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(parent, ^"z", parent.groundHeight, fallDuration)
    if parent.has_node("PacketShow"):
        tween.tween_property(parent.get_node("PacketShow"), ^"position:y", - parent.groundHeight, fallDuration)
    tween.set_trans(Tween.TRANS_BOUNCE)
    tween.tween_property(parent.transformPoint, ^"scale", Vector2(0.75, 1.25), fallDuration)
    tween.set_parallel(false)
    tween.set_trans(Tween.TRANS_BOUNCE)
    tween.tween_property(parent.transformPoint, ^"scale", Vector2(1.5, 0.5), 0.1)
    tween.tween_property(parent.transformPoint, ^"scale", Vector2.ONE, 0.2)
