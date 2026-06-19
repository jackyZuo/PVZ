@tool
extends AdobeAnimateSpriteBase

@onready var presentBoxHead: AdobeAnimateSpriteBase = %PresentBoxHead
@onready var presentBoxImpHead: AdobeAnimateSpriteBase = %PresentBoxImpHead

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if presentBoxHead.is_node_ready():
        presentBoxHead.pause = pause
        presentBoxHead.light_mask = light_mask

    if presentBoxImpHead.is_node_ready():
        presentBoxImpHead.pause = pause
        presentBoxImpHead.light_mask = light_mask
