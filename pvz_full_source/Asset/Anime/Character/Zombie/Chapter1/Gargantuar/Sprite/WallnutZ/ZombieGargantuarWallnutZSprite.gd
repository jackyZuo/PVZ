@tool
extends AdobeAnimateSpriteBase

@onready var wallnutZHead: AdobeAnimateSpriteBase = %WallnutZHead
@onready var peashooterZImpHead: AdobeAnimateSpriteBase = %PeashooterZImpHead

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if wallnutZHead.is_node_ready():
        wallnutZHead.pause = pause
        wallnutZHead.light_mask = light_mask

    if peashooterZImpHead.is_node_ready():
        peashooterZImpHead.pause = pause
        peashooterZImpHead.light_mask = light_mask
