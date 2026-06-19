@tool
extends TowerDefensePlant

@export var changeCost: TowerDefensePacketChangeCost

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.invincible = true
    instance.canBeCollection = false
    changeCost = changeCost.duplicate()
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        changeCost.method = "Increase"
    await get_tree().physics_frame
    if TowerDefenseManager.IsGameRunning():
        TowerDefenseManager.ChangeCostAdd(changeCost)

func _exit_tree() -> void :
    if Engine.is_editor_hint():
        return
    TowerDefenseManager.ChangeCostRemove(changeCost)

func PreSpawn() -> void :
    super.PreSpawn()
    TowerDefenseManager.ChangeCostAdd(changeCost)

func SleepEntered() -> void :
    super.SleepEntered()
    instance.invincible = false
    instance.canBeCollection = true

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    changeCost.method = "Increase"
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        changeCost.method = "Decrease"
