@tool
extends TowerDefenseCoinBase

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    remove_from_group("Coin")



func Collection() -> void :
    super.Collection()
