@tool
extends TowerDefensePlant

var run: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    add_to_group("AppleBack")

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
    if !run:
        Run()

func Run() -> void :
    AudioManager.AudioPlay("Apple", AudioManagerEnum.TYPE.SFX)
    sprite.SetAnimation("Running", true, 0.2)
    instance.invincible = true
    run = true
    TowerDefenseManager.backPacket = true
    TowerDefenseManager.backZombie = true
    await get_tree().create_timer(8.0, false).timeout
    Destroy()

func DestroySet() -> void :
    super.DestroySet()
    remove_from_group("AppleBack")
    await get_tree().physics_frame
    if get_tree().get_node_count_in_group("AppleBack") - 1 <= 0:
        TowerDefenseManager.backPacket = false
        TowerDefenseManager.backZombie = false

func ExportVariantSave() -> Dictionary:
    return {
        "run": run, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    run = data.get("run", false)
