@tool
extends TowerDefenseZombie

const ZOMBIE_PAPER_MADHEAD = preload("uid://s4hnj2igecma")

var hasTarget: bool = true

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Target":
            hasTarget = false
            Walk()

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if !TowerDefenseManager.IsGameRunning():
        return
    if !TowerDefenseManager.IsIZM2Mode():
        if global_position.x > groundRight:
            global_position.x -= 100.0 * delta

func Walk() -> void :
    if hasTarget:
        Idle()
    else:
        super.Walk()

func Spawn() -> void :
    global_position.x = TowerDefenseManager.GetMapCellPlantPos(Vector2(randi_range(TowerDefenseManager.GetMapGridNum().x - 2, TowerDefenseManager.GetMapGridNum().x), gridPos.y)).x
