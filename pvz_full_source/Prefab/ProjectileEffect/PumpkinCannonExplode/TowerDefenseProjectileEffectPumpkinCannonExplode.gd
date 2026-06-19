extends TowerDefenseProjectileEffectBase

const PUMPKIN_CANNON_EXPLOSION = preload("uid://q3mewkbjcbor")

func _ready() -> void :
    if is_instance_valid(target):
        EffectCreate()
        TowerDefenseExplode.CreateExplode(global_position, Vector2(1.0, 0.2), eventList, [], camp, -1)
    else:
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantPumpkin")
        if is_instance_valid(cell):
            if cell.CanPacketPlant(packetConfig):
                var pumpkin: TowerDefensePlant = packetConfig.Plant(gridPos)
                if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
                    pumpkin.Hypnoses()
            elif cell.HasPlant():
                for i in 5:
                    if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
                        TowerDefenseManager.BrainSunCreate(global_position, 25, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                    else:
                        TowerDefenseManager.SunCreate(global_position, 25, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            else:
                EffectCreate()
        else:
            EffectCreate()
    await get_tree().physics_frame
    queue_free()

func EffectCreate() -> void :
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 3.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(PUMPKIN_CANNON_EXPLOSION, gridPos)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    effect.global_position = global_position
    if is_instance_valid(cell):
        effect.global_position.y -= (cell.GetGroundHeight() - 30)
    characterNode.add_child(effect)
    AudioManager.AudioPlay("MineExplosion", AudioManagerEnum.TYPE.SFX)
