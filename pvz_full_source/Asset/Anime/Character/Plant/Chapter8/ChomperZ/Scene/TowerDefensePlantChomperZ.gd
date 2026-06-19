@tool
extends TowerDefensePlant

@onready var chomperComponent: ChomperComponent = %ChomperComponent
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var timerComponent: TimerComponent = %TimerComponent

@export var chewTime: float = 30.0:
    set(_chewTime):
        chewTime = _chewTime
        if !is_node_ready():
            await ready
        chomperComponent.chewTime = chewTime

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause:
                if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                    timerComponent.Run("Spawn", 25.0)
                    return
                var zombie = CreateCharacter("ZombieNormalChomper", global_position, gridPos, 0.0)
                zombie.Rise(2.5)
                if !instance.hypnoses:
                    zombie.Hypnoses()
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt("ZombieNormalChomper", gridPos.x, gridPos.y, _sync_id, instance.hitpointScale, transformPoint.scale.x, !instance.hypnoses, 2.5, true, global_position.x, global_position.y)
            timerComponent.Run("Spawn", 25.0)

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 1.75
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 25.0)

func ExportVariantSave() -> Dictionary:
    return {
        "chewTime": chewTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    chewTime = data.get("chewTime", 30.0)
