@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
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
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 6.5

func Attack() -> void :
    fireParticles.restart()
    AudioManager.AudioPlay("Fume", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackEventExecute()
    var projectile = fireComponent.CreateProjectileByData(0, Vector2(600, 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), -1, camp, Vector2.ZERO)
    if projectile == null:
        return
    projectile.projectileBodyNode.scale.x = scale.x
    projectile.gridPos = gridPos

func ExportVariantSave() -> Dictionary:
    return {
        "fireInterval": fireInterval, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    fireInterval = data.get("fireInterval", 2.0)
