@tool
extends TowerDefensePlant

const TOWER_DEFENSE_PROJECTILE_EFFECT_GLOOM_SQUASH = preload("uid://b3y8v3hddvg")

@onready var squashComponent: SquashComponent = %SquashComponent
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var attackComponent2: AttackComponent = %AttackComponent2

@onready var collisionShape: CollisionShape2D = %CollisionShape

@export var fireInterval: float = 2.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75

    instance.hitpointsEmpty.disconnect(Destroy)
    instance.invincible = true
    instance.keepAlive = true
    await get_tree().create_timer(0.1, false).timeout
    if !attackComponent2.CanAttack():
        instance.invincible = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if instance.hitpoints <= 0:
        if !squashComponent.alive:
            ToSquash()
            return
        else:
            Destroy()
            return

func Attack() -> void :
    var effect = TOWER_DEFENSE_PROJECTILE_EFFECT_GLOOM_SQUASH.instantiate()
    effect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    effect.global_position = global_position
    characterNode.add_child(effect)

func ToSquash() -> void :
    attackComponent.alive = false
    attackComponent2.alive = true
    instance.invincible = true
    squashComponent.alive = true
    instance.hitpoints = 300
    instance.die = false
    die = false

func ExportVariantSave() -> Dictionary:
    return {
        "fireInterval": fireInterval, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    fireInterval = data.get("fireInterval", 2.0)
