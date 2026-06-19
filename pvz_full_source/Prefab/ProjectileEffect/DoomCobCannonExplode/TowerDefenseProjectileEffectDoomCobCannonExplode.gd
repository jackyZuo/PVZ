extends TowerDefenseProjectileEffectBase

const DOOM_SHROOM_EXPLOSION = preload("uid://0hfxonqijrv0")

func _ready() -> void :
    EffectCreate()
    await get_tree().physics_frame
    queue_free()

func EffectCreate() -> void :
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    ViewManager.FullScreenColorBlink(Color.DARK_SLATE_BLUE, 0.5, false)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(DOOM_SHROOM_EXPLOSION, gridPos)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    effect.global_position = global_position
    if is_instance_valid(cell):
        effect.global_position -= Vector2(0, cell.GetGroundHeight() - 30)
    characterNode.add_child(effect)
    await get_tree().physics_frame
    TowerDefenseExplode.CreateExplode(global_position, Vector2(3.5, 3.5), eventList, [], camp, -1)
    AudioManager.AudioPlay("ExplodeDoomShroom", AudioManagerEnum.TYPE.SFX)
    var craterPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("CraterDayGround")
    craterPacket.Plant(gridPos, false, true)
