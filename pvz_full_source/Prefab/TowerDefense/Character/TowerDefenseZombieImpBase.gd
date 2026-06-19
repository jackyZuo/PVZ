@tool
class_name TowerDefenseZombieImpBase extends TowerDefenseZombie

@export var flyAnimeClip: String = "Fly"
@export var landAnimeClip: String = "Land"

var collectonFlagsSave: int
var maskFlagsSave: int

var throw: bool = false
var landOver: bool = false
var impThrowComponent: ImpThrowComponent

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if is_instance_valid(componentManager):
        impThrowComponent = componentManager.GetComponentFromType("ImpThrowComponent")
    collectonFlagsSave = instance.collisionFlags
    maskFlagsSave = instance.maskFlags
    if throw:
        Fly.call_deferred()

func WalkEntered() -> void :
    super.WalkEntered()

func FlyEntered() -> void :
    impThrowComponent.FlyEntered()

@warning_ignore("unused_parameter")
func FlyProcessing(delta: float) -> void :
    impThrowComponent.FlyProcessing(delta)

func FlyExited() -> void :
    pass

func LandEntered() -> void :
    impThrowComponent.LandEntered()

@warning_ignore("unused_parameter")
func LandProcessing(delta: float) -> void :
    impThrowComponent.LandProcessing(delta)

func LandExited() -> void :
    pass

func Fly() -> void :
    impThrowComponent.Fly()

func Land() -> void :
    impThrowComponent.Land()

@warning_ignore("unused_parameter")
func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    if impThrowComponent.AnimeCompleted(clip):
        return
    match clip:
        landAnimeClip:
            Walk()

func ExportVariantSave() -> Dictionary:
    return {
        "throw": throw, 
        "landOver": landOver, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    throw = data.get("throw", false)
    landOver = data.get("landOver", false)
