@tool
extends TowerDefenseGravestone

@onready var changeProjectileStateComponent: ChangeProjectileStateComponent = %ChangeProjectileStateComponent
@onready var changeCheckArea: Area2D = %ChangeCheckArea
@onready var changeCheckShape: CollisionShape2D = %ChangeCheckShape

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    changeCheckShape.shape = changeCheckShape.shape.duplicate(true)
    changeCheckShape.shape.size = TowerDefenseManager.GetMapGridSize() * Vector2(3, 3)
    changeCheckArea.process_mode = Node.PROCESS_MODE_INHERIT

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage3", "Damage4", "Damage5":
            changeProjectileStateComponent.alive = false
            sprite.SetFliters(["wave1", "wave2", "shock"], false)
