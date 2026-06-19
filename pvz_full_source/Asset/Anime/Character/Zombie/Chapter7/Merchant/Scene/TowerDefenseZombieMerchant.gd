@tool
extends TowerDefenseZombie

@export var changeCost: TowerDefensePacketChangeCost

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater"], true)
    changeCost = changeCost.duplicate()
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        changeCost.method = "Decrease"
    await get_tree().physics_frame
    if TowerDefenseManager.IsGameRunning():
        TowerDefenseManager.ChangeCostAdd(changeCost)

func PreSpawn() -> void :
    super.PreSpawn()
    TowerDefenseManager.ChangeCostAdd(changeCost)

func _exit_tree() -> void :
    if Engine.is_editor_hint():
        return
    TowerDefenseManager.ChangeCostRemove(changeCost)

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    changeCost.method = "Decrease"
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        changeCost.method = "Increase"
