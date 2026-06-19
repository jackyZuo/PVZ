@tool
extends AdobeAnimateSpriteBase

@onready var head: AdobeAnimateSpriteBase = %Head

var shake: bool = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if !canRun || !shake:
        return
    offset = Vector2(0, -100) + Vector2(randf_range(-1, 1), randf_range(-1, 1))
    if !is_instance_valid(head):
        return
    if head.is_node_ready():
        head.pause = pause
        head.light_mask = light_mask
