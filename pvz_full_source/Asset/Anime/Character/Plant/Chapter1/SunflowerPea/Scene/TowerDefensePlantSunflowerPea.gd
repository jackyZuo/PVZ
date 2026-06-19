@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent
@onready var produceComponent: ProduceComponent = %ProduceComponent

@export var fireInterval: float = 3.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName


@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval
@export var sunNum: int = 25:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum


func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    timeScaleInit = 1.25

func UnlimitedFireInit() -> void :
    fireInterval /= 2.0
    produceComponent.product.connect(UnlimitedFireProduct)
    produceComponent.onlyEmit = true
    produceInterval /= 3.0

func UnlimitedFireProduct(_pos: int = -1, _num: int = 25) -> void :
    await get_tree().physics_frame
    if fireComponent.CanFireCheckOnceByName(projectileName, instance.collisionFlags + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
        var posOffset: Vector2 = Vector2.UP
        var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(1, Vector2(600, 0), TowerDefenseProjectileCreateData.new(&"Sun"), instance.collisionFlags + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE, camp)
        var tween = projectile.create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_QUART)
        tween.tween_property(projectile, ^"global_position", projectile.global_position + posOffset * 50.0, 0.5)
    else:
        produceComponent.Create(produceComponent.marker[0].global_position, _num)

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {"fireNum": fireNum, 
        "projectileName": projectileName, 
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "Pea")
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
    fireInterval = data.get("fireInterval", 3.0)
