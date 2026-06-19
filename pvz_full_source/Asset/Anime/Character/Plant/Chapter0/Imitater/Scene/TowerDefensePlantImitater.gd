@tool
extends TowerDefensePlant

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

@export var packetBank: String

func Explode() -> void :
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)

    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return

    var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData(packetBank)
    if is_instance_valid(packetBankData):
        var packetList: Array = packetBankData.GetCategory("White") + packetBankData.GetCategory("Original")
        var packetRandom: String = packetList.pick_random()
        var _packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
        while (_packetConfig.characterConfig is TowerDefensePlantConfig && ((instance.hypnoses && (_packetConfig.characterConfig.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES)) || !cell.CanPacketPlant(_packetConfig))) && packetList.size() > 1:
            packetList.erase(packetRandom)
            packetRandom = packetList.pick_random()
            _packetConfig = TowerDefenseManager.GetPacketConfig(packetRandom)

        if _packetConfig.characterConfig is TowerDefensePlantConfig:
            var plant = _packetConfig.Plant(gridPos, true)
            if is_instance_valid(plant):
                plant.WeakUp.call_deferred()
                plant.SetSpriteGroupShaderParameter("imitater", true)
                if instance.hypnoses:
                    plant.Hypnoses()
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, plant)
                        MultiPlayerManager.SendSpawnCharacterAt(_packetConfig.saveKey, gridPos.x, gridPos.y, _sync_id)
        if _packetConfig.characterConfig is TowerDefenseZombieConfig:
            var zombie = _packetConfig.Create(global_position, gridPos)
            if is_instance_valid(zombie):
                characterNode.add_child(zombie)
                zombie.instance.wakeUp = true
                if instance.hypnoses:
                    zombie.Hypnoses()
                zombie.Walk.call_deferred()
                zombie.SetSpriteGroupShaderParameter("imitater", true)
                if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                    var control = TowerDefenseManager.currentControl
                    if is_instance_valid(control):
                        var _sync_id: int = control._get_next_sync_id()
                        control._register_sync_character(_sync_id, zombie)
                        MultiPlayerManager.SendSpawnCharacterAt(_packetConfig.saveKey, gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, instance.hypnoses, 0.0, true, global_position.x, global_position.y, true)

func ExportVariantSave() -> Dictionary:
    return {
        "packetBank": packetBank, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    packetBank = data.get("packetBank", "")
