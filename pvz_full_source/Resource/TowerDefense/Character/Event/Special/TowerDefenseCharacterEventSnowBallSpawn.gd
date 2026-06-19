class_name TowerDefenseCharacterEventSnowBallSpawn extends TowerDefenseCharacterEventBase

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    pass

func Export() -> Dictionary:
    return {
        "EventName": "SnowBallSpawn", 
        "Value": {}
    }

static func Run(target: TowerDefenseCharacter) -> void :
    if target.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ItemSnowBall")
    var ball = packetConfig.Create(target.global_position, target.gridPos, target.groundHeight)
    characterNode.add_child(ball)
    var size: String = ""
    if target is TowerDefenseZombie:
        if target.camp != TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
            ball.Hypnoses()
        if target.instance.zombiePhysique <= TowerDefenseEnum.ZOMBIE_PHYSIQUE.SMALL:
            size = "Small"
        elif target.instance.zombiePhysique <= TowerDefenseEnum.ZOMBIE_PHYSIQUE.NORMAL:
            size = "Normal"
        else:
            size = "Large"
        ball.SetSize(size)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, ball)
            MultiPlayerManager.SendSpawnCharacterAt("ItemSnowBall", target.gridPos.x, target.gridPos.y, _sync_id, 1.0, 1.0, target.camp != TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE, 0.0, true, target.global_position.x, target.global_position.y, false, target.groundHeight, size)
