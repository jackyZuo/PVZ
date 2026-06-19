class_name ImpThrowComponent extends ComponentBase

var parent: TowerDefenseZombieImpBase

func GetName() -> String:
    return "ImpThrowComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func FlyEntered() -> void :
    AudioManager.AudioPlay("Imp", AudioManagerEnum.TYPE.SFX)
    parent.instance.collisionFlags = 0
    parent.instance.maskFlags = 0
    parent.sprite.SetAnimation(parent.flyAnimeClip, false, 0.2)

@warning_ignore("unused_parameter")
func FlyProcessing(delta: float) -> void :
    parent.sprite.timeScale = parent.timeScale * 0.8
    if parent.z <= parent.groundHeight:
        Land()

func LandEntered() -> void :
    parent.sprite.SetAnimation(parent.landAnimeClip, false, 0.2)

@warning_ignore("unused_parameter")
func LandProcessing(delta: float) -> void :
    parent.sprite.timeScale = parent.timeScale

func Fly() -> void :
    if parent.flyAnimeClip == "":
        return
    parent.state.send_event("ToFly")

func Land() -> void :
    if parent.landAnimeClip == "":
        return
    if parent.landOver:
        return
    parent.landOver = true
    parent.instance.collisionFlags = parent.collectonFlagsSave
    parent.instance.maskFlags = parent.maskFlagsSave
    parent.state.send_event("ToLand")

func AnimeCompleted(clip: String) -> bool:
    if clip == parent.landAnimeClip:
        parent.Walk()
        return true
    return false
