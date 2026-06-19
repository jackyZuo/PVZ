@tool
extends TowerDefenseGravestone

const SKELETON_EXPLOSION = preload("uid://dykgix28gj14b")

var over: bool = false
var timer: float = 0.0
var time: float = 30.0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    remove_from_group("Gravestone")

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.currentControl || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !over:
        if !sprite.pause:
            if timer < time:
                timer += delta * timeScale
            else:
                over = true
                if nearDie || die:
                    return
                if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                    Destroy()
                    return
                var zombiePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieSkeletuar")
                var zombie: TowerDefenseZombie = zombiePacket.Create(global_position, gridPos, 0)
                zombie.over = true
                characterNode.add_child(zombie)
                var _hitpointScale: float = instance.hitpointScale
                var _scale: Vector2 = transformPoint.scale
                ( func():
                    if is_instance_valid(zombie):
                        if is_instance_valid(zombie.instance):
                            zombie.instance.hitpointScale = _hitpointScale
                        if is_instance_valid(zombie.transformPoint):
                            zombie.transformPoint.scale = _scale).call_deferred()
                zombie.set_deferred("invisible", invisible)
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt("ZombieSkeletuar", gridPos.x, gridPos.y, _sync_id, _hitpointScale, _scale.x, false, 0.0, true, global_position.x, global_position.y, true)
                Destroy()

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    AudioManager.AudioPlay("ZamboniExplosion", AudioManagerEnum.TYPE.SFX)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(SKELETON_EXPLOSION, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
