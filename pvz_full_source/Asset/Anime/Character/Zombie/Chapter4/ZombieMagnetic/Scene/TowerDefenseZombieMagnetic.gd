@tool
extends TowerDefenseZombie

@onready var changeProjectileStateComponent: ChangeProjectileStateComponent = %ChangeProjectileStateComponent
@onready var changeCheckArea: Area2D = %ChangeCheckArea
@onready var changeCheckShape: CollisionShape2D = %ChangeCheckShape

var openTimer: float = 0.0
var openTime: float = 0.0
var open: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    changeCheckShape.shape = changeCheckShape.shape.duplicate(true)
    changeCheckShape.shape.size = TowerDefenseManager.GetMapGridSize() * Vector2(5, 5)
    openTime = randf_range(6.0, 12.0)
    if randf() > 0.5:
        sprite.SetFliter("anim_tongue", true)
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !open:
        if openTimer < openTime:
            openTimer += delta
        else:
            open = true
            changeCheckArea.process_mode = Node.PROCESS_MODE_INHERIT
            sprite.SetFliters(["wave2", "wave1", "Zombie_bodyater", "shock"], true)
            sprite.SetFliters(["Zombie_bodyater2"], false)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    super.ArmorDamagePointReach(armorName, stage)
    match armorName:
        "HelmetMagnet":
            if stage == 1:
                sprite.SetFliters(["shock"], false)

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "HelmetMagnet":
            changeCheckShape.shape.size = TowerDefenseManager.GetMapGridSize() * Vector2(3, 3)

func ExportVariantSave() -> Dictionary:
    return {
        "openTimer": openTimer, 
        "openTime": openTime, 
        "open": open, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    openTimer = data.get("openTimer", 0.0)
    openTime = data.get("openTime", 0.0)
    open = data.get("open", false)
