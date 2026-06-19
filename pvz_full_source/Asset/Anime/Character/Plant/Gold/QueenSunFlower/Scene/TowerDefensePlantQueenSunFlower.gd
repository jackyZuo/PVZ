@tool
extends TowerDefensePlant

@export var eventList: Array[TowerDefenseCharacterEventBase] = []
@export var allEventList: Array[TowerDefenseCharacterEventBase] = []

@onready var attackShape: CollisionShape2D = %AttackShape
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var fireComponent: FireComponent = %FireComponent

@export var attackInterval: float = 3
@export var fireInterval: float = 3
@export var fireNum: int = 6
@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval
@export var sunNum: int = 150:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

var currentFireNum: int = 0
var attackTimer: float = 0.0

@export var projectileName: String = "FirePea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

var skinName: String = "Default":
    set(_skinName):
        skinName = _skinName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileData.skinName = skinName

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if currentCustom.has("Custom0"):
        skinName = "Note"

    attackShape.shape = attackShape.shape.duplicate(true)
    attackShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75

    fireComponent.fireInterval = fireInterval

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        skinName = "Note"
    else:
        skinName = "Default"

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale

    if Engine.get_physics_frames() % 2 == 0:
        TowerDefenseExplode.CreateExplode(global_position, Vector2(1.3, 1.3), allEventList, [], TowerDefenseEnum.CHARACTER_CAMP.ALL, -1)

    if attackTimer >= attackInterval:
        if attackComponent.CanAttack():
            TowerDefenseExplode.CreateExplode(global_position, Vector2(1.3, 1.3), eventList, [], camp, instance.collisionFlags)
            attackTimer = 0.0
    else:
        attackTimer += delta

    if fireComponent.CanFireByData(fireComponent.fireCheckList[0].projectile.GetProjetile()):
        fireComponent.Refresh()
        for i in fireNum:
            var angle: float = deg_to_rad(360.0 / fireNum * float(i))
            var posOffset: Vector2 = Vector2.from_angle(angle)
            var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(600, 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), -1, camp, Vector2.ZERO)
            var tween = projectile.create_tween()
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_QUART)
            tween.tween_property(projectile, ^"global_position", projectile.global_position + posOffset * 50.0, 0.5)
            await get_tree().create_timer(0.1, false).timeout

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {"attackInterval": attackInterval, 
        "fireNum": fireNum, 
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "currentFireNum": currentFireNum, 
        "attackTimer": attackTimer, 
        "projectileName": projectileName, 
        "skinName": skinName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    attackInterval = data.get("attackInterval", 3)
    fireNum = data.get("fireNum", 6)
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 150)
    currentFireNum = data.get("currentFireNum", 0)
    attackTimer = data.get("attackTimer", 0.0)
    projectileName = data.get("projectileName", "FirePea")
    skinName = data.get("skinName", "Default")
    fireInterval = data.get("fireInterval", 3)
