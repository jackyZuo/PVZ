@tool
extends TowerDefenseZombie

const ZOMBIE_PAPER_MADHEAD = preload("uid://bbu3gjf3ww3e7")
const HAMMER_EXPLOSION = preload("res://Prefab/Particles/Explosion/Hammer/HammerExplosion.tscn")

var angry: bool = false
var canRun: bool = true
var isRun: bool = false
var isGrap: bool = false

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func GaspEntered() -> void :
    isGrap = true
    sprite.SetAnimation("Gasp", false, 0.1)

@warning_ignore("unused_parameter")
func GaspProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func GaspExited() -> void :
    isGrap = false

func RunEntered() -> void :
    isRun = true
    sprite.SetAnimation("AngryRun", true, 0.0)
    await get_tree().create_timer(0.1, false).timeout
    groundMoveComponent.alive = true

@warning_ignore("unused_parameter")
func RunProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if attackComponent.CanAttack():
        state.send_event("ToImpact")

func RunExited() -> void :
    isRun = false
    groundMoveComponent.alive = false

func ImpactEntered() -> void :
    sprite.SetAnimation("Impact", false, 0.0)

@warning_ignore("unused_parameter")
func ImpactProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 0.25

func ImpactExited() -> void :
    pass

func RestEntered() -> void :
    sprite.SetAnimation("Rest", false, 0.0)
    sprite.AddAnimation("Up", 0.0, false, 0.0)

@warning_ignore("unused_parameter")
func RestProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 0.5

func RestExited() -> void :
    pass

func WalkEntered():
    if !angry:
        sprite.SetAnimation(walkAnimeClip, true, 0.2)
    else:
        if canRun:
            state.send_event("ToRun")
            canRun = false
            return
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
        "Helmet":
            if isRun:
                Walk()
            canRun = false

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Gasp":
            AudioManager.AudioPlay("NewspaperRarrgh", AudioManagerEnum.TYPE.SFX)
            sprite.SetReplace("Zombie_head.png", ZOMBIE_PAPER_MADHEAD)
            timeScaleInit = 3.0
            angry = true
            isGrap = false
            Walk()
        "Impact":
            state.send_event("ToRest")
        "Up":
            Walk()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "impact":
            if attackComponent.CanAttack():
                AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
                var effect = TowerDefenseManager.CreateEffectParticlesOnce(HAMMER_EXPLOSION, gridPos)
                effect.global_position = global_position
                characterNode.add_child(effect)
                var impactTarget = attackComponent.target
                if is_instance_valid(impactTarget):
                    impactTarget.AttackDeal(self, attackComponent.attackType, 500.0)
                    if is_instance_valid(impactTarget.cell):
                        impactTarget.cell.AttackDeal(self, attackComponent.attackType, 500.0)
                    impactTarget.Hurt(500.0, true, Vector2.ZERO)
                var tween = create_tween()
                tween.set_ease(Tween.EASE_OUT)
                tween.set_trans(Tween.TRANS_QUAD)
                tween.tween_property(self, ^"global_position:x", global_position.x + 50.0 * scale.x, 0.1)

func Walk() -> void :
    if isGrap:
        return
    super.Walk()
