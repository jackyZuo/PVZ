class_name PlantAnimeComponent extends ComponentBase

var parent: TowerDefensePlant

func GetName() -> String:
    return "PlantAnimeComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func PlantEntered() -> void :
    if parent.plantAnimeClip == "":
        parent.Idle()
        return
    if !parent.sprite.flashAnimeData.HasClip(parent.plantAnimeClip):
        parent.Idle()
        return
    parent.sprite.SetAnimation(parent.plantAnimeClip, false)

@warning_ignore("unused_parameter")
func PlantProcessing(delta: float) -> void :
    parent.sprite.timeScale = parent.timeScale

func PlantExited() -> void :
    pass

func AnimeCompleted(clip: String) -> bool:
    if clip == parent.plantAnimeClip:
        parent.Idle()
        return true
    return false
