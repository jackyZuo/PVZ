@tool
extends TowerDefensePlant

const TABOO_DOOM_SHROOM_CUSTOM_0_EXPLOSION = preload("uid://cs13qb2gi1km7")
@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if currentCustom.has("Custom0"):
        explodeComponent.explodeEffect = TABOO_DOOM_SHROOM_CUSTOM_0_EXPLOSION

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        explodeComponent.explodeEffect = TABOO_DOOM_SHROOM_CUSTOM_0_EXPLOSION

func SleepEntered() -> void :
    super.SleepEntered()
    instance.invincible = false
