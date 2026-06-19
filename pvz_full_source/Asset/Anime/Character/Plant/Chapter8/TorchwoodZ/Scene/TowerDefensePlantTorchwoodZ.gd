@tool
extends TowerDefensePlant

@onready var light: PointLight2D = %Light
@onready var timerComponent: TimerComponent = %TimerComponent

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause:
                if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                    timerComponent.Run("Spawn", 25.0)
                    return
                var zombie = CreateCharacter("ZombieDancerFire", global_position, gridPos, 0.0)
                zombie.Rise(2.5)
                if !instance.hypnoses:
                    zombie.Hypnoses()
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt("ZombieDancerFire", gridPos.x, gridPos.y, _sync_id, instance.hitpointScale, transformPoint.scale.x, !instance.hypnoses, 2.5, true, global_position.x, global_position.y)
            timerComponent.Run("Spawn", 25.0)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Spawn"):
        timerComponent.Run("Spawn", 25.0)
    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")
