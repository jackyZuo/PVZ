@tool
extends TowerDefensePlant
const TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM = preload("uid://bto1eksfijahm")

@onready var fireComponent: FireComponent = %FireComponent
@onready var attackComponent: AttackComponent = %AttackComponent

@onready var collisionShape: CollisionShape2D = %CollisionShape

@export var fireInterval: float = 3.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval
        attackComponent.attackInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75

func Attack() -> void :
    var effect = TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM.instantiate()
    effect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    effect.global_position = global_position
    characterNode.add_child(effect)

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    fireInterval = data.get("fireInterval", 3.0)
