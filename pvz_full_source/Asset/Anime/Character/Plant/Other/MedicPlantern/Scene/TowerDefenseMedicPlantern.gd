@tool
extends TowerDefensePlant

@onready var collisionShape: CollisionShape2D = %CollisionShape
@onready var checkArea: Area2D = %CheckArea
@onready var timerComponent: TimerComponent = %TimerComponent

var _healRange: Vector2

func _ready() -> void :
    super._ready()
    AudioManager.AudioPlay("Plantern", AudioManagerEnum.TYPE.SFX)
    collisionShape.shape = collisionShape.shape.duplicate(true)
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75
    _healRange = TowerDefenseManager.GetMapGridSize() * 2.75 * 0.5

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.alive:
        timerComponent.alive = true
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 1.0)

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause && !instance.sleep:
                var characterList: Array = TowerDefenseManager.GetCampFriendly(camp)
                for character: TowerDefenseCharacter in characterList:
                    if character is TowerDefensePlantBowlingBase:
                        continue
                    if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                        continue
                    if character.instance.hitpoints >= character.instance.hitpointsSave:
                        continue
                    var distance: Vector2 = (character.global_position - global_position).abs()
                    if distance.x > _healRange.x || distance.y > _healRange.y:
                        continue
                    character.Health(0.01 * character.instance.hitpointsSave)
                    if character.instance.hitpoints >= character.instance.hitpointsSave:
                        character.instance.hitpoints = character.instance.hitpointsSave
            timerComponent.Run("Spawn", 1.0)
