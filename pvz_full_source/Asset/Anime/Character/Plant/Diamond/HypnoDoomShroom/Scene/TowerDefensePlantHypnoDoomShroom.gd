@tool
extends TowerDefensePlant

const HYPNO_DOOM_SHROOM_EXPLOSION_CUSTOM_0 = preload("uid://h4noqc3yscoo")

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if currentCustom.has("Custom0"):
        explodeComponent.explodeEffect = HYPNO_DOOM_SHROOM_EXPLOSION_CUSTOM_0

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        explodeComponent.explodeEffect = HYPNO_DOOM_SHROOM_EXPLOSION_CUSTOM_0

func SleepEntered() -> void :
    super.SleepEntered()
    instance.invincible = false
