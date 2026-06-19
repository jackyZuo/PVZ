class_name TowerDefenseCharacterBuffButter extends TowerDefenseCharacterBuffConfig

const BUTTER_SPLAT = preload("uid://cf2k7klghh2nl")

@export var time: float = 8.0
@export_storage var currentTime: float = 0.0
@export_storage var butterSprite: Sprite2D

func _init() -> void :
    key = "Butter"

func Enter() -> void :
    if character.instance.maskFlags == 0 || character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
        character.buff.BuffDelete("Butter")
        return
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.BUTTER:
        character.buff.BuffDelete("Butter")
        return
    if !is_instance_valid(butterSprite):
        butterSprite = Sprite2D.new()
        butterSprite.texture = BUTTER_SPLAT
        butterSprite.rotation = -0.4
        butterSprite.scale.x = character.scale.x * character.sprite.scale.x
        character.spriteGroup.add_child(butterSprite)
        if is_instance_valid(character.headSlot):
            character.headSlot.Update()
            butterSprite.global_position = character.headSlot.global_position + Vector2(-5, -10)
        else:
            if character is TowerDefenseZombie:
                butterSprite.global_position = character.sprite.global_position + Vector2(-25, -30)
            if character is TowerDefensePlant:
                butterSprite.global_position = character.sprite.global_position + Vector2(25, -25)
                butterSprite.scale.x *= -1


@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    character.timeScale *= 0.0
    return character.nearDie || character.die || currentTime >= time

func Exit() -> void :
    if is_instance_valid(butterSprite):
        butterSprite.queue_free()

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time)
    currentTime = 0.0
