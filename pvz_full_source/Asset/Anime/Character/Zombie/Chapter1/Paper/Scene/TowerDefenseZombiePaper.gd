@tool
extends TowerDefenseZombie

const ZOMBIE_PAPER_MADHEAD = preload("uid://s4hnj2igecma")

var angry: bool = false

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func GaspEntered() -> void :
    sprite.SetAnimation("Gasp", false, 0.0)

@warning_ignore("unused_parameter")
func GaspProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func GaspExited() -> void :
    pass

func WalkEntered():
    if !angry:
        sprite.SetAnimation(walkAnimeClip, true, 0.2)
    else:
        sprite.SetAnimation("AngryWalk", true, 0.0)
    await get_tree().create_timer(0.1, false).timeout
    groundMoveComponent.alive = true

func AttackEntered():
    if !angry:
        sprite.SetAnimation(attackAnimeClip, true, 0.2)
    else:
        sprite.SetAnimation("AngryEat", true, 0.2)
    startAttack = false
    await get_tree().create_timer(0.1, false).timeout
    startAttack = true

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Paper":
            state.send_event("ToGasp")
            AudioManager.AudioPlay("NewspaperRip", AudioManagerEnum.TYPE.SFX)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Gasp":
            AudioManager.AudioPlay("NewspaperRarrgh", AudioManagerEnum.TYPE.SFX)
            sprite.SetReplace("Zombie_head.png", ZOMBIE_PAPER_MADHEAD)
            timeScaleInit = 3.0
            angry = true
            Walk()

func ExportVariantSave() -> Dictionary:
    return {
        "angry": angry, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    angry = data.get("angry", false)
