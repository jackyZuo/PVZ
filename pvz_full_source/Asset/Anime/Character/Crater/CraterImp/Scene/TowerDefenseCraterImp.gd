@tool
extends TowerDefenseCrater

var over: bool = false

func DieDown() -> void :
    if over:
        return
    over = true
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var zombiePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieImpSkeleton")
    var zombie: TowerDefenseZombie = zombiePacket.Create(global_position, gridPos, 0.0)
    zombie.over = true
    characterNode.add_child(zombie)
    await get_tree().create_timer(0.1, false).timeout
    if is_instance_valid(zombie):
        zombie.Walk()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt("ZombieImpSkeleton", gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, false, 0.0, true, global_position.x, global_position.y, true)
    await get_tree().physics_frame
    Destroy()
