@tool
extends TowerDefensePlant

var canCopy: bool = true

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if !is_instance_valid(packet):
        return
    if packet.GetCost() != 0:
        return
    await get_tree().physics_frame
    if instance.hologram:
        canCopy = false
    if !canCopy:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(config.name)
    var characterOverride: TowerDefenseCharacterOverride = TowerDefenseCharacterOverride.new()
    var propertyChangeConfig: TowerDefenseCharacterPropertyChangeConfig = TowerDefenseCharacterPropertyChangeConfig.new()
    propertyChangeConfig.propertyName = "canCopy"
    propertyChangeConfig.value = false
    characterOverride.propertyChange = [propertyChangeConfig]
    var override: TowerDefensePacketOverride = TowerDefensePacketOverride.new()
    override.characterOverride = characterOverride
    packetConfig.override = override
    SpawnPacket(packetConfig, global_position, 15, false)

func ExportVariantSave() -> Dictionary:
    return {
        "canCopy": canCopy
    }

func ImportVariantSave(data: Dictionary) -> void :
    canCopy = data.get("canCopy", true)
