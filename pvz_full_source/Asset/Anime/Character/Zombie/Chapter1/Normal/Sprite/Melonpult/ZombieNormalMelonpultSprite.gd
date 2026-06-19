@tool
extends AdobeAnimateSpriteBase

@onready var head: AdobeAnimateSpriteBase = %Head

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !is_instance_valid(head):
        return
    if head.is_node_ready():
        head.pause = pause
        head.light_mask = light_mask
