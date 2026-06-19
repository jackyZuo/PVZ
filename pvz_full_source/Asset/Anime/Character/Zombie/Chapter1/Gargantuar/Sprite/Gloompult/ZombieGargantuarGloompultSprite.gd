@tool
extends AdobeAnimateSpriteBase

@onready var gloompultHead: AdobeAnimateSpriteBase = %GloompultHead
@onready var puffShroomImpHead: AdobeAnimateSpriteBase = %PuffShroomImpHead

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if gloompultHead.is_node_ready():
        gloompultHead.pause = pause
        gloompultHead.light_mask = light_mask

    if puffShroomImpHead.is_node_ready():
        puffShroomImpHead.pause = pause
        puffShroomImpHead.light_mask = light_mask
