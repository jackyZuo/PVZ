@tool
extends TowerDefenseZombie

var pop: bool = false

var swing: bool = false

var speed: float = 25.0

var audioPlay: bool = false

@onready var timerComponent: TimerComponent = %TimerComponent

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 15.0)

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !pop:
                if !sprite.pause:
                    state.send_event("ToSwing")
                timerComponent.Run("Spawn", 15.0)

func FlyEntered() -> void :
    sprite.SetAnimation("Idle", true, 0.2)

@warning_ignore("unused_parameter")
func FlyProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if !sprite.pause:
        global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)

    if global_position.x < TowerDefenseManager.GetMapGroundLeft() + 20:
        instance.ArmorDelete("Aircraft")
        return
    if !audioPlay:
        if global_position.x < TowerDefenseManager.GetMapGroundRight():
            AudioManager.AudioPlay("BalloonInflate", AudioManagerEnum.TYPE.SFX)
            audioPlay = true
    if !sprite.pause && attackComponent.CanAttack():
        if is_instance_valid(attackComponent.target) && attackComponent.target is TowerDefenseZombie:
                attackComponent.Attack(config.smashAttack)

func FlyExited() -> void :
    pass

func SwingEntered() -> void :
    swing = true
    sprite.SetAnimation("Swing", true, 0.2)
    await get_tree().create_timer(2.0, false).timeout
    Walk()

@warning_ignore("unused_parameter")
func SwingProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if !sprite.pause:
        global_position.x -= 3 * speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
    if global_position.x < TowerDefenseManager.GetMapGroundLeft() + 20:
        instance.ArmorDelete("Aircraft")
        return

func SwingExited() -> void :
    swing = false

func PopEntered() -> void :
    sprite.SetAnimation("Pop", false, 0.2)

@warning_ignore("unused_parameter")
func PopProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func PopExited() -> void :
    pass

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func Walk() -> void :
    if pop:
        state.send_event("ToWalk")
    else:
        state.send_event("ToFly")

func Blow() -> void :
    if !pop && !swing:
        BlowBack(0.5, 0.2)
        state.send_event("ToSwing")

func BlowBack(num: float, time: float = 1.0) -> void :
    if !pop && !swing:
        super.BlowBack(num, time)
        state.send_event("ToSwing")

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Pop":
            Walk()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Aircraft":
            timerComponent.alive = false
            pop = true
            AudioManager.AudioPlay("BalloonPop", AudioManagerEnum.TYPE.SFX)
            instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
            instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
            instance.unUseBuffFlags = 0
            state.send_event("ToPop")

func ExportVariantSave() -> Dictionary:
    return {
        "pop": pop, 
        "speed": speed, 
        "swing": swing
    }

func ImportVariantSave(data: Dictionary) -> void :
    pop = data.get("pop", false)
    speed = data.get("speed", 25.0)
    swing = data.get("swing", false)
