@tool
extends TowerDefensePlant

@onready var cannonComponent: CannonComponent = %CannonComponent
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var fireParticles: GPUParticles2D = %FireParticles

@export var fireInterval: float = 2.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

@export var restTime: float = 30:
    set(_restTime):
        restTime = _restTime
        if !is_node_ready():
            await ready
        cannonComponent.restTime = restTime

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 6.5

func Attack() -> void :
    fireParticles.restart()
    AudioManager.AudioPlay("Fume", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackEventExecute()

func ExportVariantSave() -> Dictionary:
    return {"restTime": restTime, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    restTime = data.get("restTime", 30)
    fireInterval = data.get("fireInterval", 2.0)
