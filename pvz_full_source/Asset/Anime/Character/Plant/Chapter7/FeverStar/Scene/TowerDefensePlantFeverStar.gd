@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 2:
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

@export var projectileName: String = "FeverStar":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

var damageScale: float = 1.0
var projectileScale: float = 1.0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    BattleEventBus.jalaLineEffectEmit.connect(JalaLineCheck)
    BattleEventBus.jalaRowEffectEmit.connect(JalaRowCheck)
    BattleEventBus.jalaGridEffectEmit.connect(JalaGridCheck)

func JalaLineCheck(line: int) -> void :
    if line == gridPos.y:
        LevelUp()

func JalaRowCheck(row: int) -> void :
    if row == gridPos.x:
        LevelUp()

func JalaGridCheck(_gridPos: Vector2i) -> void :
    if _gridPos == gridPos:
        LevelUp()

func LevelUp() -> void :
    if damageScale < 5.0:
        damageScale += 1.0
    if projectileScale < 2.0:
        projectileScale += 0.25


func FireProjectile(projectile: TowerDefenseProjectile) -> void :
    projectile.damage *= damageScale
    projectile.projectileSprite.scale *= projectileScale

func ExportVariantSave() -> Dictionary:
    return {"damageScale": damageScale, 
        "projectileScale": projectileScale, 
        "fireNum": fireNum, 
        "projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    damageScale = data.get("damageScale", 1.0)
    projectileScale = data.get("projectileScale", 1.0)
    fireNum = data.get("fireNum", 1)
    projectileName = data.get("projectileName", "FeverStar")
    fireInterval = data.get("fireInterval", 2)
