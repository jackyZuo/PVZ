
class_name MoveComponent extends ComponentBase


@export var velocity: Vector2 = Vector2.ZERO

@export var gravity: float = 0.0

@export var moveScale: float = 1.0


var parent: CanvasItem


func GetName() -> String:
    return "MoveComponent"


func _ready() -> void :
    if get_parent() is ComponentManager:
        parent = get_parent().parent
    else:
        parent = get_parent()


func _physics_process(delta) -> void :
    if !alive:
        return
    if gravity:
        velocity.y += gravity * delta * moveScale
    parent.global_position += velocity * delta * moveScale



func SetVelocity(_velocity: Vector2 = Vector2.ZERO):
    velocity = _velocity



func SetGravity(_gravity: float = 0.0):
    gravity = _gravity


func MoveClear():
    velocity = Vector2.ZERO
    gravity = 0.0

func ExportComponentSave() -> Dictionary:
    return {
        "velocityX": velocity.x, 
        "velocityY": velocity.y, 
        "gravity": gravity, 
        "moveScale": moveScale, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    velocity = Vector2(_data.get("velocityX", 0.0), _data.get("velocityY", 0.0))
    gravity = _data.get("gravity", 0.0)
    moveScale = _data.get("moveScale", 1.0)

func SyncSerialize() -> Dictionary:
    return {
        "velocityX": velocity.x, 
        "velocityY": velocity.y, 
        "gravity": gravity, 
        "moveScale": moveScale, 
    }

func SyncDeserialize(data: Dictionary) -> void :
    velocity = Vector2(data.get("velocityX", 0.0), data.get("velocityY", 0.0))
    gravity = data.get("gravity", 0.0)
    moveScale = data.get("moveScale", 1.0)
