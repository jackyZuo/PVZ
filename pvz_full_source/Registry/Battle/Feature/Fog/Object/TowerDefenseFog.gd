extends Node2D

@onready var sprite: Sprite2D = %Sprite
@onready var area: Area2D = %Area
@onready var shape: CollisionShape2D = %Shape

var canVisible: bool = true
var beginColumn: int = 6
var gridPos: Vector2 = Vector2.ZERO
var savePos: Vector2

func _ready() -> void :
    savePos = global_position
    var size: Vector2 = TowerDefenseManager.GetMapGridSize()
    shape.shape = shape.shape.duplicate(true)
    shape.shape.size = size

    sprite.frame = randi_range(0, 7)

func _physics_process(delta: float) -> void :
    if !canVisible:
        sprite.modulate.a = lerpf(sprite.modulate.a, 0.0, delta * 2.0)
    else:
        if beginColumn != gridPos.x:
            sprite.modulate.a = lerpf(sprite.modulate.a, 1.0, delta * 2.0)
        else:
            sprite.modulate.a = lerpf(sprite.modulate.a, 0.75, delta * 2.0)

func AreaEntered(_area: Area2D) -> void :
    canVisible = !area.has_overlapping_areas()

func AreaExited(_area: Area2D) -> void :
    await get_tree().physics_frame
    canVisible = !area.has_overlapping_areas()
