@tool
extends TowerDefensePlant

const TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM = preload("uid://bto1eksfijahm")

@onready var attackComponent: AttackComponent = %AttackComponent

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

func Cover(character: TowerDefenseCharacter) -> void :
    if character.config.name == "PlantFumeShroom":
        if character.instance.wakeUp:
            instance.wakeUp = true

func Attack() -> void :
    var effect = TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM.instantiate()
    effect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    effect.global_position = global_position
    characterNode.add_child(effect)

func ExportVariantSave() -> Dictionary:
    return {
        "fireInterval": fireInterval, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    fireInterval = data.get("fireInterval", 2.0)
