
class_name GroundHeightComponent extends ComponentBase


@export var interpolationSpeed: float = 3.0

@export var threshold: float = 0.1

@export var waterHeight: float = 25.0

@export var ladderHeight: float = 60.0

@export var handleWaterHeight: bool = false

@export var handleLadder: bool = false

@export var detectWater: bool = false

@export var detectLadder: bool = false


var parent: TowerDefenseCharacter

var onLadder: bool = false

var _gridSize: Vector2

var waterInteractionComponent: WaterInteractionComponent


var _waterExitCooldown: float = 0.0

func GetName() -> String:
    return "GroundHeightComponent"


func _ready() -> void :
    parent = get_parent().parent
    _gridSize = TowerDefenseManager.GetMapGridSize()


func _physics_process(delta: float) -> void :
    if !alive:
        return
    if !is_instance_valid(parent.cell):
        return
    if _waterExitCooldown > 0.0:
        _waterExitCooldown -= delta
    if detectWater || detectLadder:
        if (Engine.get_physics_frames() + parent.randFreshIndex) % 5 == 0:
            DetectEnvironment()
    if !handleWaterHeight && parent.inWater:
        return
    var targetHeight: float = GetTargetHeight()
    if abs(parent.groundHeight - targetHeight) > threshold:
        parent.groundHeight = lerpf(parent.groundHeight, targetHeight, interpolationSpeed * delta)
    else:
        parent.groundHeight = targetHeight


func DetectEnvironment() -> void :
    if !is_instance_valid(parent.cell):
        return
    var cellPercentage: float = parent.cellPercentage
    if detectLadder:
        onLadder = (parent.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE) && is_instance_valid(parent.cell.characterLadder) && parent.config.physique < TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE && parent.scale.x > 0.0
    if detectWater:
        var newInWater: bool = ( !onLadder || (onLadder && cellPercentage <= 0.5)) && parent.cell.IsWater() && !(parent.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE)
        if parent.inWater != newInWater:
            if !newInWater:
                _waterExitCooldown = 0.5
                parent.inWater = newInWater
            elif _waterExitCooldown <= 0.0:
                parent.inWater = newInWater


func GetTargetHeight() -> float:
    if handleLadder:
        if onLadder && parent.cellPercentage > 0.5:
            return ladderHeight
    if handleWaterHeight && parent.inWater:
        if "waterHeight" in parent:
            return - parent.waterHeight
        return - waterHeight
    return parent.cell.GetGroundHeight(parent.cellPercentage)
