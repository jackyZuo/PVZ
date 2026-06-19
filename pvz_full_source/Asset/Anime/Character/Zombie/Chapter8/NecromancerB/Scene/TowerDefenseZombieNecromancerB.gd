@tool
extends TowerDefenseZombie

@export var shootingTime: float = 10.0
var shootingTimer: float = 0.0
const SIZE_UP = preload("uid://bt1c4oos7k1vo")

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if die || nearDie:
        return
    if !sprite.pause:
        if shootingTimer < shootingTime:
            shootingTimer += delta * timeScale
        else:
            state.send_event("ToShooting")
            shootingTimer = 0.0

func ShootingEntered() -> void :
    AudioManager.AudioPlay("Skeleton", AudioManagerEnum.TYPE.SFX)
    sprite.SetAnimation("Shooting", true, 0.2)
    var characterList: Array = TowerDefenseManager.GetCampFriendlyLine(self)
    characterList = characterList.filter(
        func(_character: TowerDefenseCharacter):
            if _character == self:
                return false
            if _character is not TowerDefenseZombie:
                return false
            if _character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                return false
            if _character.sizeUpNum <= 0:
                return false
            if (_character.global_position.x > global_position.x) != instance.hypnoses:
                return false
            return true
    )
    if characterList.is_empty():
        return
    var character: TowerDefenseCharacter = characterList.pick_random()
    character.instance.hitpointScale *= 1.5
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(SIZE_UP, character.gridPos, "Idle")
    characterNode.add_child(effect)
    effect.gridPos = character.gridPos
    effect.global_position = character.global_position
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUINT)
    tween.tween_property(character.transformPoint, "scale", 1.2 * character.transformPoint.scale, 0.4)
    character.sizeUpNum -= 1

@warning_ignore("unused_parameter")
func ShootingProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.5

func ShootingExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Shooting":
            Walk()
