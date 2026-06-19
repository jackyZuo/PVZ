extends TowerDefenseProjectileEffectBase

const MINE_EXPLOSION = preload("uid://dqcu2ycvf4u72")

func _ready() -> void :
    if is_instance_valid(target):
        EffectCreate()
        TowerDefenseExplode.CreateExplode(global_position, Vector2(1.0, 0.2), eventList, [], camp, -1)
        if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
            TowerDefenseManager.BrainSunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
        else:
            TowerDefenseManager.SunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
    else:
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantSunMine")
        if is_instance_valid(cell):
            if cell.CanPacketPlant(packetConfig):
                var sunMine = packetConfig.Plant(gridPos)
                if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
                    sunMine.Hypnoses()
                await get_tree().physics_frame
                sunMine.ReadyRise()
            else:
                if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
                    TowerDefenseManager.BrainSunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                else:
                    TowerDefenseManager.SunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                EffectCreate()
        else:
            if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
                TowerDefenseManager.BrainSunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            else:
                TowerDefenseManager.SunCreate(global_position, 50, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 0.0, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            EffectCreate()
    await get_tree().physics_frame
    queue_free()

func EffectCreate() -> void :
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 3.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(MINE_EXPLOSION, gridPos)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    effect.global_position = global_position
    if is_instance_valid(cell):
        effect.global_position.y -= (cell.GetGroundHeight() - 30)
    characterNode.add_child(effect)
    AudioManager.AudioPlay("MineExplosion", AudioManagerEnum.TYPE.SFX)
