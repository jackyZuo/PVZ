@tool
extends TowerDefensePlant

@onready var timerComponent: TimerComponent = %TimerComponent
@onready var mousePressComponent: MousePressComponent = %MousePressComponent

var isTanglekelp: bool = false

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Open"):
        timerComponent.Run("Open")

func OpenEntered() -> void :
    isTanglekelp = randf() < 0.1

    sprite.SetAnimation("OpenB" if isTanglekelp else "OpenA", false, 0.2)

@warning_ignore("unused_parameter")
func OpenProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func OpenExited() -> void :
    pass

func OpenIdleEntered() -> void :
    mousePressComponent.alive = true
    if instance.hypnoses:
        Pressed(global_position)
        mousePressComponent.alive = false
    sprite.SetAnimation("IdleB" if isTanglekelp else "IdleA", true, 0.2)

@warning_ignore("unused_parameter")
func OpenIdleProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func OpenIdleExited() -> void :
    mousePressComponent.alive = false

func CloseEntered() -> void :
    sprite.SetAnimation("Close", true, 0.2)

@warning_ignore("unused_parameter")
func CloseProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func CloseExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "OpenA", "OpenB":
            state.send_event("ToOpenIdle")
        "Close":
            Idle()

func Timeout(timerName: String) -> void :
    match timerName:
        "Open":
            state.send_event("ToOpen")


@warning_ignore("unused_parameter")
func Pressed(pos: Vector2) -> void :
    if TowerDefenseManager.GetSun() < (50 if isTanglekelp else 25) && !instance.hypnoses:
        return
    if TowerDefenseManager.IsIZMMode():
        TowerDefenseManager.UseSun(50 if isTanglekelp else 25)
    else:
        BrainSunCreate(global_position, 50 if isTanglekelp else 25)
    state.send_event("ToClose")
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var zombie_name: String = "ZombieSnorkleTanglekelp" if isTanglekelp else "ZombieSnorkle"
    var zombie = CreateCharacter(zombie_name, global_position, gridPos, groundHeight)
    zombie.Walk.call_deferred()
    if !instance.hypnoses:
        zombie.Hypnoses()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt(zombie_name, gridPos.x, gridPos.y, _sync_id, instance.hitpointScale, transformPoint.scale.x, !instance.hypnoses, 0.0, true, global_position.x, global_position.y, true, groundHeight)

func ExportVariantSave() -> Dictionary:
    return {
        "isTanglekelp": isTanglekelp, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    isTanglekelp = data.get("isTanglekelp", false)
