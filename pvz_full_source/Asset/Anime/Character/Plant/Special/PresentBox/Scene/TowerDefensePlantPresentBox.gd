@tool
extends TowerDefensePlant

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

@export var packetBank: String

func Explode() -> void :
    explodeComponent.CreateParticlesEffect()

    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return

    var packetBankData: TowerDefensePacketBankData
    if packetBank == "PlantPresentBox":
        packetBankData = TowerDefenseManager.GetPacketBankData(packetBank if randf() > 0.5 else "GeneralPlant")
    else:
        packetBankData = TowerDefenseManager.GetPacketBankData(packetBank)
    if is_instance_valid(packetBankData):
        var plantList: Array = packetBankData.GetPlantList()
        var plantRandom: String = plantList.pick_random()
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(plantRandom)
        while ((instance.hypnoses && (packetConfig.characterConfig.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES)) || !cell.CanPacketPlant(packetConfig)) && plantList.size() > 1:
            plantList.erase(plantRandom)
            plantRandom = plantList.pick_random()
            packetConfig = TowerDefenseManager.GetPacketConfig(plantRandom)
        if plantList.size() > 1:
            var plant = packetConfig.Plant(gridPos, true)
            plant.WakeUp.call_deferred()
            if instance.hypnoses:
                plant.Hypnoses()
            if Global.isMultiplayerMode and MultiPlayerManager.isHost:
                var control = TowerDefenseManager.currentControl
                if is_instance_valid(control):
                    var _sync_id: int = control._get_next_sync_id()
                    control._register_sync_character(_sync_id, plant)
                    MultiPlayerManager.SendSpawnCharacterAt(plantRandom, gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, instance.hypnoses)

func ExportVariantSave() -> Dictionary:
    return {
        "packetBank": packetBank, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    packetBank = data.get("packetBank", "")
