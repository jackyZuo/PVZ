@tool
extends AdobeAnimateSpriteBase

@onready var back: AdobeAnimateSpriteBase = %Back

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    back.frameIndex = frameIndex
    back.elapsedTimer = elapsedTimer

func SetClip(_clip: String) -> void :
    super.SetClip(_clip)
    if is_instance_valid(back):
        back.SetClip(_clip)
