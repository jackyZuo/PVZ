@tool
extends TowerDefenseZombie

@onready var timerComponent: TimerComponent = %TimerComponent

var scare: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    bodyHurt.connect( func(_num: int):
        if !sprite.pause && !scare && sprite.timeScale > 0:
            ChangeLine()
    )

func WalkProcessing(delta: float) -> void :
    super.WalkProcessing(delta)
    if !sprite.pause && sprite.timeScale > 0 && instance.hitpoints <= instance.hitpointsSave / 2:
        state.send_event("ToScare")

func ScareEntered() -> void :
    sprite.timeScale = timeScale * 2
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER
        sprite.SetAnimation("Scaredwater", false)
        sprite.AddAnimation("IdleWater", true)
    else:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
        sprite.SetAnimation("Scared", false)
        sprite.AddAnimation("IdleScare", true)

@warning_ignore("unused_parameter")
func ScareProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    scare = true
    timerComponent.alive = true
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 1.0)
    if instance.hitpoints >= instance.hitpointsSave:
        instance.hitpoints = instance.hitpointsSave
        if !sprite.pause && sprite.timeScale > 0:
            state.send_event("ToUp")

func ScareExited() -> void :
    scare = false
    timerComponent.alive = false
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

func UpEntered() -> void :
    sprite.timeScale = timeScale * 2
    if inWater:
        sprite.SetAnimation("UpWater", false)
    else:
        sprite.SetAnimation("Up", false)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Up", "UpWater":
            Walk()

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !nearDie && !sprite.pause && sprite.timeScale > 0:
                Health(25)
            if scare:
                timerComponent.Run("Spawn", 1.0)

func ExportVariantSave() -> Dictionary:
    return {
        "scare": scare
    }

func ImportVariantSave(data: Dictionary) -> void :
    scare = data.get("scare", false)
