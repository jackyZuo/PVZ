class_name SwimComponent extends ComponentBase

var parent: TowerDefenseZombie

func GetName() -> String:
    return "SwimComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func WalkEntered() -> void :
    if parent.inWater:
        if !parent.inSwimPlay && parent.inSwimAnimeClip != "":
            parent.sprite.SetAnimation(parent.inSwimAnimeClip, false, 0.2)
            parent.sprite.AddAnimation(parent.swimAnimeClip, 0.0, true, 0.0)
            parent.inSwimPlay = true
        else:
            parent.sprite.SetAnimation(parent.swimAnimeClip, true, 0.0)
    else:
        if parent.waterInteractionComponent.outFromWater:
            parent.waterInteractionComponent.outFromWater = false
            parent.sprite.SetAnimation(parent.walkAnimeClip, true, 0.0)
        else:
            parent.sprite.SetAnimation(parent.walkAnimeClip, true, 0.2)

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    if parent.sprite.clip != parent.inSwimAnimeClip:
        if parent.global_position.x > parent.groundRight:
            parent.sprite.timeScale = parent.timeScale * parent.walkSpeedScale * 2.0
        else:
            parent.sprite.timeScale = parent.timeScale * parent.walkSpeedScale
    else:
        parent.sprite.timeScale = parent.timeScale * parent.inSwimAnimeClipScale

func InWater() -> void :
    if !parent.isRise:
        parent.groundHeight = - parent.waterHeight
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if parent.swimAnimeClip != parent.walkAnimeClip:
        if !parent.die && !parent.nearDie:
            parent.Walk()

func OutWater() -> void :
    parent.global_position.x -= sign(parent.scale.x) * 5.0
    parent.inSwimPlay = false
    if parent.outSwimAnimeClip != "":
        parent.sprite.SetAnimation(parent.outSwimAnimeClip, false, 0.2)
    if parent.swimAnimeClip != parent.walkAnimeClip:
        if !parent.die && !parent.nearDie:
            parent.waterInteractionComponent.outFromWater = true
            parent.Walk()

func AnimeCompleted(clip: String) -> void :
    if parent.inSwimAnimeClip != "":
        if clip == parent.inSwimAnimeClip:
            parent.CreateSplash()
            if parent.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER:
                AudioManager.AudioPlay("ZombieEnteringWater", AudioManagerEnum.TYPE.SFX)
            else:
                AudioManager.AudioPlay("PlantWater", AudioManagerEnum.TYPE.SFX)

func ExportComponentSave() -> Dictionary:
    return {
        "inSwimPlay": parent.inSwimPlay if is_instance_valid(parent) else false, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    if is_instance_valid(parent):
        parent.inSwimPlay = _data.get("inSwimPlay", false)
