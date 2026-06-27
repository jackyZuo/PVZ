@tool
extends TowerDefensePlant

var over: bool = false

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if instance.sleep:
        return
    if over:
        return
    if !is_instance_valid(character):
        return
    if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES:
        SkipInvincibleHurt(num)
        return
    if type == "Eat":
        over = true
        if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
            character.skipDestroySet = true
            character.Destroy()
            Destroy()
            return
        character.skipDestroySet = true
        character.Destroy()
        var zombiePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieGargantuarRedEyes")
        var zombie: TowerDefenseZombie = zombiePacket.Create(character.global_position, character.gridPos, 0.0)
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
            var _sync_id: int = TowerDefenseManager.currentControl._get_next_sync_id()
            TowerDefenseManager.currentControl._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt("ZombieGargantuarRedEyes", character.gridPos.x, character.gridPos.y, _sync_id, 1.0, 1.0, !instance.hypnoses, 0.0, true, character.global_position.x, character.global_position.y, false, 0.0)
        Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
