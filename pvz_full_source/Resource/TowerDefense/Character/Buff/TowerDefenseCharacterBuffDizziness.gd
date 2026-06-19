class_name TowerDefenseCharacterBuffDizziness extends TowerDefenseCharacterBuffConfig

const STAR = preload("uid://pvjsf1qinxav")

@export var time: float = 3.0
@export_storage var currentTime: float = 0.0
@export_storage var dizzinessSprite: AdobeAnimateSprite

func _init() -> void :
    key = "Dizziness"

func Enter() -> void :
    if character.instance.maskFlags == 0 || character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
        character.buff.BuffDelete("Dizziness")
        return
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.DIZZINESS:
        character.buff.BuffDelete("Dizziness")
        return
    if is_instance_valid(character.headSlot):
        if !dizzinessSprite:
            character.headSlot.Update()
            dizzinessSprite = STAR.instantiate()
            character.spriteGroup.add_child(dizzinessSprite)
            dizzinessSprite.global_position = character.headSlot.global_position + Vector2(-5, -10)
    character.sprite.queue_redraw()

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    character.timeScale *= 0.0
    return character.nearDie || character.die || currentTime >= time

func Exit() -> void :
    if is_instance_valid(dizzinessSprite):
        dizzinessSprite.queue_free()

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time)
    currentTime = 0.0
