@tool
class_name TowerDefensePlantBowlingBase extends TowerDefensePlant

var moveComponent: MoveComponent
var waterComponent: WaterComponent
var bowlingComponent: BowlingComponent

func _ready() -> void :
    super._ready()
    if is_instance_valid(componentManager):
        moveComponent = componentManager.GetComponentFromType("MoveComponent")
        waterComponent = componentManager.GetComponentFromType("WaterComponent")
        bowlingComponent = componentManager.GetComponentFromType("BowlingComponent")

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    shadowComponent.saveShadowPosition.y = global_position.y + 30
    super._physics_process(delta)
    gridPos = TowerDefenseManager.GetMapGridPos(global_position)

func InWater() -> void :
    super.InWater()
    CreateSplash()
    Destroy()

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    moveComponent.moveScale = -1.0 if instance.hypnoses else 1.0
