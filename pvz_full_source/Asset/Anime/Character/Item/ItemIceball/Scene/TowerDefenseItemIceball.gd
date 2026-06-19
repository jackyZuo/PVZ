@tool
extends TowerDefenseItem

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var groundMoveComponent: GroundMoveComponent = %GroundMoveComponent

var _gridSize: Vector2

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    _gridSize = TowerDefenseManager.GetMapGridSize()

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !inGame:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if is_instance_valid(cell):
        inWater = cell.IsWater()
        var cellPos: Vector2 = TowerDefenseManager.GetMapCellPos(gridPos)
        var offset: Vector2 = global_position - cellPos
        cellPercentage = offset.x / _gridSize.x
        var targetHeight: float = cell.GetGroundHeight(cellPercentage)
        if abs(groundHeight - targetHeight) > 0.1:
            groundHeight = lerpf(groundHeight, targetHeight, 3.0 * delta)
        else:
            groundHeight = targetHeight

    if attackComponent.CanAttack():
        attackComponent.SmashAttackCell(1800.0)

    if global_position.x < -100:
        Destroy()

func IdleEntered() -> void :
    super.IdleEntered()
    sprite.SetAnimation("Rise", false)
    sprite.AddAnimation("Roll", 0.0, true)

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if !inGame:
        return
    groundMoveComponent.alive = true
    if sprite.clip == "Rise":
        sprite.timeScale = timeScale * 1.0
    else:
        sprite.timeScale = timeScale * 0.15

func InWater() -> void :
    super.InWater()
    Destroy()

func DestroySet() -> void :
    var effect: TowerDefenseEffectParticlesOnce
    for i in 6:
        effect = TowerDefenseManager.CreateEffectParticlesOnce(SNOW_FLAKES, gridPos)
        characterNode.add_child(effect)
        effect.global_position = global_position + Vector2.from_angle(TAU / 6 * i) * 30

@warning_ignore("unused_parameter")
func ExplodeHurt(num: float, type: String = "Bomb", playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    if sprite.clip == "Roll":
        if type == "Jala":
            Destroy()
    return 0
