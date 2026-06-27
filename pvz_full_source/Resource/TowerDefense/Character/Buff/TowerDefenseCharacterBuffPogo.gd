class_name TowerDefenseCharacterBuffPogo extends TowerDefenseCharacterBuffConfig

@export var time: float = 8.0
@export_storage var currentTime: float = 0.0

func _init() -> void :
    key = "Pogo"

func Enter() -> void :
    if character.instance.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
        character.buff.BuffDelete("Pogo")
        return
    if character is TowerDefenseZombie:
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            character.buff.BuffDelete("Pogo")
            return
    if character is TowerDefenseItem:
        character.buff.BuffDelete("Pogo")
        return
    if character is TowerDefenseGravestone:
        character.buff.BuffDelete("Pogo")
        return
    if character is TowerDefenseCrater:
        character.buff.BuffDelete("Pogo")
        return
    character.land.connect(Land)
    character.ySpeed = -300
    character.gravity = 490
    if character.inWater:
        character.groundHeight = 0.0
        if is_instance_valid(character.groundHeightComponent):
            character.groundHeightComponent.handleWaterHeight = false

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    currentTime += delta
    return character.nearDie || character.die || currentTime >= time

func Exit() -> void :
    if is_instance_valid(character):
        if is_instance_valid(character.groundHeightComponent):
            character.groundHeightComponent.handleWaterHeight = true
        if character.inWater:
            if "waterHeight" in character:
                character.groundHeight = - character.waterHeight
            elif is_instance_valid(character.groundHeightComponent):
                character.groundHeight = - character.groundHeightComponent.waterHeight
    if !character.instance.hypnoses:
        character.instance.ArmorClear()
    if character is TowerDefenseZombie:
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.CAR:
            character.Hurt(1000000)

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    time = max(time, config.time)
    currentTime = 0.0

func Land() -> void :
    character.ySpeed = -300
    if character.inWater:
        character.groundHeight = 0.0
