class_name ProjectileMethodShootYMoveSin extends TowerDefenseProjectileMethod

@export var strength: float = 30.0
@export var speed: float = 10

var timer: float = 0.0

func _init(_strength: float, _speed: float) -> void :
    strength = _strength
    speed = _speed

@warning_ignore("unused_parameter")
func Ready() -> void :
    timer = 0.0

@warning_ignore("unused_parameter")
func Process(delta: float) -> void :
    timer += delta
    projectile.global_position.y = projectile.savePos.y + sin(timer * speed) * strength
