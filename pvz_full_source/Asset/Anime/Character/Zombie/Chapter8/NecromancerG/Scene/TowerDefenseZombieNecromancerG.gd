@tool
extends TowerDefenseZombie

@onready var collisionShape: CollisionShape2D = %CollisionShape
@onready var checkArea: Area2D = %Area2D
@export var shootingTime: float = 10.0
var HEALTH2 = preload("uid://77ugapuuydxq")
var shootingTimer: float = 0.0
var over: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75

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
    var characterList: Array = TowerDefenseManager.GetCampFriendlyFromArea(camp, checkArea)
    characterList = characterList.filter( func(character: TowerDefenseCharacter):
        if character is not TowerDefenseZombie:
            return false
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return false
        return true
    )
    for character: TowerDefenseCharacter in characterList:
        character.Health(0.2 * character.instance.hitpointsSave)
        if character.instance.hitpoints >= character.instance.hitpointsSave:
            character.instance.hitpoints = character.instance.hitpointsSave
        var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(HEALTH2, character.gridPos, "Idle")
        characterNode.add_child(effect)
        effect.gridPos = character.gridPos
        effect.global_position = character.global_position

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

func DestroySet() -> void :
    if inWater:
        return
    if over:
        return
    over = true
    CraterCreate(true, "CraterNG")
    await get_tree().physics_frame
