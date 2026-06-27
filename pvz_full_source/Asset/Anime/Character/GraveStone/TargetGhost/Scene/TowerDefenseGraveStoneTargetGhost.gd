@tool
extends TowerDefenseGravestone

func HitBoxEntered(area: Area2D) -> void :
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if nearDie || die:
        return
    var character = area.get_parent()
    if character is TowerDefenseZombie:
        if character.isRise:
            return
        if character.hasGhost:
            return
        if character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND != 0 && character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE == 0:
            return
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return
        if character.camp != camp:
            return
        if !character.targetRegistrationComponent.canCarry:
            return
        if character.gridPos.y != gridPos.y:
            return
        if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
            Hurt(200)
            return
        var zombiePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieGhost")
        var zombie: TowerDefenseZombie = zombiePacket.Create(global_position, gridPos, groundHeight)
        zombie.carryCharacter = character
        characterNode.add_child(zombie)
        await get_tree().create_timer(0.1, false).timeout
        if is_instance_valid(zombie):
            zombie.Walk()
        Hurt(200)
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, zombie)
                MultiPlayerManager.SendSpawnCharacterAt("ZombieGhost", gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, false, 0.0, true, global_position.x, global_position.y, true, groundHeight)
