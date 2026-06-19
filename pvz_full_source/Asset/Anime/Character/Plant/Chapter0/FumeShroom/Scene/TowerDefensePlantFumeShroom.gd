@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var fireParticles: GPUParticles2D = %FireParticles

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
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 4.5

func Attack() -> void :
    fireParticles.restart()
    AudioManager.AudioPlay("Fume", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackEventExecute()

func ExportVariantSave() -> Dictionary:
    return {
        "fireInterval": fireInterval, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    fireInterval = data.get("fireInterval", 2.0)
