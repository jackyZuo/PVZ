@tool
extends AdobeAnimateSpriteBase

@onready var head1: AdobeAnimateSpriteBase = %Head1
@onready var head2: AdobeAnimateSpriteBase = %Head2
@onready var head3: AdobeAnimateSpriteBase = %Head3

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if head1.is_node_ready():
        head1.pause = pause
        head1.light_mask = light_mask
    if head2.is_node_ready():
        head2.pause = pause
        head2.light_mask = light_mask
    if head3.is_node_ready():
        head3.pause = pause
        head3.light_mask = light_mask
