@tool
extends TowerDefensePlant

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if !inGame:
        sprite.back.z_index = 0
