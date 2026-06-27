@tool
extends TowerDefensePlant

@onready var bloverComponent: BloverComponent = %BloverComponent

var run: bool = false

func IdleEntered() -> void :
    if !inGame:
        return
    if !TowerDefenseManager.currentControl.isGameRunning:
        return
    Run()

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale * 2.0
    if !inGame:
        return
    if !TowerDefenseManager.currentControl.isGameRunning:
        return

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "blow":
            bloverComponent.Execult()

func Run() -> void :
    sprite.SetAnimation("Blow", false, 0.2)
    sprite.AddAnimation("Loop", 0.0, true, 0.0)
    instance.invincible = true
    for character: TowerDefenseCharacter in TowerDefenseManager.GetCampFriendly(camp):
        character.WakeUp()
        var coffeeBuff: TowerDefenseCharacterBuffCoffee = TowerDefenseCharacterBuffCoffee.new()
        character.BuffAdd(coffeeBuff)
    run = true

func BlowOver() -> void :
    Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "run": run, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    run = data.get("run", false)
