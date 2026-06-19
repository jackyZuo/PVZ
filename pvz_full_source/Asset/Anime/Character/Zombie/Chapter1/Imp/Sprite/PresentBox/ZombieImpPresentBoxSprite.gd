@tool
extends AdobeAnimateSpriteBase

@onready var presentBoxImpHead: AdobeAnimateSpriteBase = %PresentBoxImpHead

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if presentBoxImpHead.is_node_ready():
        presentBoxImpHead.pause = pause
        presentBoxImpHead.light_mask = light_mask
