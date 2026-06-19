@tool
class_name TowerDefenseEffectParticlesOnce extends TowerDefenseEffectBase

const TOWER_DEFENSE_EFFECT_PARTICLES_ONCE = preload("uid://dbyd0mqkya1j3")

@export var objectId: ObjectManagerConfig.OBJECT = ObjectManagerConfig.OBJECT.NOONE
@export var particles: GPUParticles2DMerge

static func Create() -> TowerDefenseEffectParticlesOnce:
    return TOWER_DEFENSE_EFFECT_PARTICLES_ONCE.instantiate()

func Refresh() -> void :
    add_to_group("Effect")
    if is_instance_valid(particles):
        particles.Init()

func Recycle() -> void :
    remove_from_group("Effect")

func _ready() -> void :
    if particles:
        if !particles.finished.is_connected(Finish):
            particles.finished.connect(Finish)

func InitScene(scene: GPUParticles2DMerge) -> void :
    add_to_group("Effect")
    particles = scene
    particles.Init()
    add_child(particles)
    particles.finished.connect(Finish)

func Init(particlesScene: PackedScene) -> void :
    InitScene(particlesScene.instantiate())

@warning_ignore("unused_parameter")
func Finish() -> void :
    if objectId == ObjectManagerConfig.OBJECT.NOONE:
        queue_free()
    else:
        ObjectManager.PoolPush(objectId, self)
