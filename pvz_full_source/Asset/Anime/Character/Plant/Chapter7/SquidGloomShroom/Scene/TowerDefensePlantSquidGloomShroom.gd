@tool
extends TowerDefensePlant

const TOWER_DEFENSE_PROJECTILE_EFFECT_GLOOM_SQUID = preload("uid://bexrfifm3d11i")
const TOWER_DEFENSE_PROJECTILE_EFFECT_GLOOM_SQUID_BIG = preload("uid://cc2e55hq70tn6")

@onready var attackComponent: AttackComponent = %AttackComponent

@onready var collisionShape: CollisionShape2D = %CollisionShape

var over: bool = false

@export var fireInterval: float = 2.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75

func DestroySet() -> void :
    if over:
        return
    over = true
    var effect = TOWER_DEFENSE_PROJECTILE_EFFECT_GLOOM_SQUID_BIG.instantiate()
    effect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    effect.global_position = global_position
    characterNode.add_child(effect)

func Attack() -> void :
    var effect = TOWER_DEFENSE_PROJECTILE_EFFECT_GLOOM_SQUID.instantiate()
    effect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    effect.global_position = global_position
    characterNode.add_child(effect)

func ExportVariantSave() -> Dictionary:
    return {"over": over, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
    fireInterval = data.get("fireInterval", 2.0)
