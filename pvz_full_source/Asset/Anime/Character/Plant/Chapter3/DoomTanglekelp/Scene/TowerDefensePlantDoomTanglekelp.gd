@tool
extends TowerDefensePlant

@onready var tanglekelpComponent: TanglekelpComponent = %TanglekelpComponent

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

@warning_ignore("unused_parameter")
func Drag(character: TowerDefenseCharacter, success: bool) -> void :
    explodeComponent.Explode()

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if currentCustom.has("Custom0"):
        tanglekelpComponent.grabFliterOpen = ["skin4", "skin5"]
        tanglekelpComponent.grabFliterClose = ["Layer 29", "Layer 32"]

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        tanglekelpComponent.grabFliterOpen = ["skin4", "skin5"]
        tanglekelpComponent.grabFliterClose = ["Layer 29", "Layer 32"]
    else:
        tanglekelpComponent.grabFliterOpen = []
        tanglekelpComponent.grabFliterClose = []
