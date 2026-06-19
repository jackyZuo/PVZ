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
        if character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE == 0:
            return
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return
        if character.camp != camp:
            return
        if character.gridPos.y != gridPos.y:
            return
        if character.instance.explosionHurt != 0:
            character.instance.explosionHurtSave = character.instance.explosionHurt
            character.instance.explosionHurt = 0

func HitBoxExited(area: Area2D) -> void :
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
        if character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE == 0:
            return
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return
        if character.camp != camp:
            return
        if character.gridPos.y != gridPos.y:
            return
        var _cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(character.gridPos)
        if (_cell.HasCharacter(config.name)):
            return
        if character.instance.explosionHurt == 0:
            if character.instance.explosionHurtSave >= 0:
                character.instance.explosionHurt = character.instance.explosionHurtSave
            else:
                character.instance.explosionHurt = -1
