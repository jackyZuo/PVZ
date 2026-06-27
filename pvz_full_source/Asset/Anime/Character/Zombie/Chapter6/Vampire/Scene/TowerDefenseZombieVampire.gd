@tool
extends TowerDefenseZombie

const DRAIN = preload("uid://je8no5cuugta")

var drainTime = 10.0
var drainTimer: float = 0.0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if TowerDefenseManager.GetMapIsVampire():
        instance.hitpointScale = 1.5
        transformPoint.scale = Vector2.ONE * 1.2

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if die || nearDie:
        return
    if drainTimer < drainTime:
        drainTimer += delta * timeScale
    else:
        state.send_event("ToShooting")
        drainTimer = 0.0
    if TowerDefenseManager.GetMapIsNight():
        instance.dealHurtScale = 1.0
    else:
        instance.dealHurtScale = 2.0

@warning_ignore("unused_parameter")
func AttackProcessing(delta: float) -> void :
    if !attackComponent.CanAttack():
        Walk()
    else:
        if startAttack && !nearDie && !sprite.pause && sprite.timeScale > 0 && useAttackDps:
            attackComponent.AttackDps(delta, config.attack)
            if !TowerDefenseManager.GetMapIsVampire():
                var health = attackComponent.HealthDps(delta, config.attack)
                instance.hitpoints += health

    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func ShootingEntered() -> void :
    sprite.SetAnimation("Shooting", false, 0.0)

@warning_ignore("unused_parameter")
func ShootingProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func ShootingExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Shooting":
            Walk()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "shooting":
            Drain()

func Garlic() -> void :
    super.Garlic()
    Hurt(instance.hitpoints * 0.2)

func Drain() -> void :
    var characterList: Array = TowerDefenseManager.GetCampTarget(camp)
    var maxHp: float = -10000
    var maxHpCharacter: TowerDefenseCharacter = null
    for character: TowerDefenseCharacter in characterList:
        if character.instance.hitpoints > maxHp:
            maxHpCharacter = character
            maxHp = character.instance.hitpoints

    if !is_instance_valid(maxHpCharacter):
        return
    var drainHp: float = maxHpCharacter.instance.hitpoints * 0.1
    var effect = TowerDefenseManager.CreateEffectSpriteOnce(DRAIN, maxHpCharacter.gridPos)
    effect.global_position = maxHpCharacter.global_position
    characterNode.add_child(effect)
    maxHpCharacter.Hurt(drainHp)
    instance.hitpoints += drainHp
    if is_instance_valid(showHealthComponent):
        showHealthComponent.MarkDirty()
