@tool
extends TowerDefensePlant

const WALL_NUT_SKIN_1_1 = preload("uid://ccqw6dynty45q")
const WALL_NUT_SKIN_1_2 = preload("uid://bpkbxlpelgb0c")

@onready var timerComponent: TimerComponent = %TimerComponent

var over: bool = false

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("WallnutZ_skin1_1.png", WALL_NUT_SKIN_1_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("WallnutZ_skin1_1.png", WALL_NUT_SKIN_1_2)

func Timeout(timerName: String) -> void :
    match timerName:
        "Spawn":
            if !sprite.pause:
                if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                    timerComponent.Run("Spawn", 25.0)
                    return
                var zombie = CreateCharacter("ZombieNormalWallnut", global_position, gridPos, groundHeight)
                zombie.Rise(2.5)
                if !instance.hypnoses:
                    zombie.Hypnoses()
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt("ZombieNormalWallnut", gridPos.x, gridPos.y, _sync_id, instance.hitpointScale, transformPoint.scale.x, !instance.hypnoses, 2.5, true, global_position.x, global_position.y, false, groundHeight)
            timerComponent.Run("Spawn", 25.0)

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
        timerComponent.Run("Spawn", 25.0)

func DestroySet() -> void :
    if over:
        return
    over = true
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var zombiePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieGargantuar")
    var zombie: TowerDefenseZombie = zombiePacket.Create(global_position, gridPos, groundHeight)
    characterNode.add_child(zombie)
    if !instance.hypnoses:
        zombie.Hypnoses()
    zombie.state.process_mode = Node.PROCESS_MODE_DISABLED
    var tween = zombie.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(zombie.transformPoint, ^"scale", Vector2.ONE, 0.5).from(Vector2.ONE * 0.5)
    tween.finished.connect(
        func():
            if is_instance_valid(zombie):
                zombie.Walk()
                zombie.state.process_mode = Node.PROCESS_MODE_INHERIT
    )
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt("ZombieGargantuar", gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, !instance.hypnoses, 0.0, true, global_position.x, global_position.y, true, groundHeight)
    Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
