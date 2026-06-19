@tool
extends TowerDefensePlantBowlingBase

@export var packetBank: String = "WallnutBowling"

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

@warning_ignore("unused_parameter")
func Bowling(character: TowerDefenseCharacter) -> void :
    moveComponent.velocity = Vector2.ZERO
    bowlingComponent.isRoll = false
    sprite.timeScale = timeScale * 2.0
    sprite.SetAnimation("Open", false, 0.1)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Open":
            var _gridPos: Vector2i = gridPos
            if !TowerDefenseManager.CheckMapGridPosIn(_gridPos):
                _gridPos = TowerDefenseManager.GetMapGridPos(global_position)
            if !TowerDefenseManager.CheckMapGridPosIn(_gridPos):
                Destroy()
                return
            var _cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(_gridPos)
            var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, _gridPos)
            effect.global_position = global_position
            characterNode.add_child(effect)
            if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                Destroy()
                return
            var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData(packetBank)
            if is_instance_valid(packetBankData):
                var packetList: Array = packetBankData.GetCategory("White") + packetBankData.GetCategory("Original") + packetBankData.GetCategory("Gold")
                var packetRandom: String = packetList.pick_random()
                var _packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
                while _packetConfig.characterConfig is TowerDefensePlantConfig && packetList.size() > 1 && ( !is_instance_valid(_cell) || !_cell.CanPacketPlant(_packetConfig)):
                    packetList.erase(packetRandom)
                    packetRandom = packetList.pick_random()
                    _packetConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
                if _packetConfig.characterConfig is TowerDefensePlantConfig:
                    var _plantGridPos: Vector2i = _gridPos
                    if is_instance_valid(_cell) && !_cell.CanPacketPlant(_packetConfig):
                        _plantGridPos = _FindNearbyEmptyCell(_gridPos, _packetConfig)
                    if TowerDefenseManager.CheckMapGridPosIn(_plantGridPos):
                        var plant = _packetConfig.Plant(_plantGridPos, true)
                        if is_instance_valid(plant):
                            plant.WeakUp.call_deferred()
                            if instance.hypnoses:
                                plant.Hypnoses()
                            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                                var control = TowerDefenseManager.currentControl
                                if is_instance_valid(control):
                                    var _sync_id: int = control._get_next_sync_id()
                                    control._register_sync_character(_sync_id, plant)
                                    MultiPlayerManager.SendSpawnCharacterAt(packetRandom, _plantGridPos.x, _plantGridPos.y, _sync_id, 1.0, 1.0, instance.hypnoses)
            Destroy()

func _FindNearbyEmptyCell(startPos: Vector2i, packetConfig: TowerDefensePacketConfig) -> Vector2i:
    for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
        var checkPos: Vector2i = startPos + offset
        if !TowerDefenseManager.CheckMapGridPosIn(checkPos):
            continue
        var _cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(checkPos)
        if is_instance_valid(_cell) && _cell.CanPacketPlant(packetConfig):
            return checkPos
    return startPos

func ExportVariantSave() -> Dictionary:
    return {
        "packetBank": packetBank, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    packetBank = data.get("packetBank", "WallnutBowling")
