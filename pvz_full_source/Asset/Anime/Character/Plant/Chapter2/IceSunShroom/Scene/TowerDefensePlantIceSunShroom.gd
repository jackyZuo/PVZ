@tool
extends TowerDefensePlant

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var over: bool = false
var run: bool = false

func SleepEntered() -> void :
    super.SleepEntered()
    instance.invincible = false

func IdleEntered() -> void :
    super.IdleEntered()
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if CanSleep():
        Sleep()
        return
    instance.invincible = true
    sprite.SetAnimation("Idle", false, 0.2)
    run = true

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale * 2.0
    if TowerDefenseManager.IsIZMMode():
        timeScaleInit = timeScaleSave

func IdleExited() -> void :
    super.IdleExited()

func AnimeCompleted(clip: String) -> void :
    if !inGame:
        return
    super.AnimeCompleted(clip)
    match clip:
        "Idle":
            if !run:
                return
            if over:
                return
            over = true
            CreateColdEffect(camp, gridPos, eventList)
            Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
        "run": run, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
    run = data.get("run", false)
