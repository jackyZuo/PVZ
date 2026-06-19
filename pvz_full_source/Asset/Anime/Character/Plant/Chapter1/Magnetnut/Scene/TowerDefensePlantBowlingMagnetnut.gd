@tool
extends TowerDefensePlantBowlingBase

@onready var magnetComponent: MagnetComponent = %MagnetComponent

var hitArmor: bool = false

var isDraw: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if config.customData:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue("PlantMagnetnut")
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            currentCustom = [packetValue["Key"]["Custom"]]

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    if is_instance_valid(magnetComponent.magnet):
        var hurt: TowerDefenseCharacterEventBowlingHurt = bowlingComponent.hitEvent[0].duplicate()
        hurt.num = 1800 + magnetComponent.breakDownArmor.hitPoints * 4.5
        bowlingComponent.hitEvent[0] = hurt
    else:
        if isDraw:
            return
        if await magnetComponent.CanArmorDraw():
            isDraw = true
            await magnetComponent.ArmorDrawNear()
            isDraw = false
        else:
            var hurt: TowerDefenseCharacterEventBowlingHurt = bowlingComponent.hitEvent[0].duplicate()
            hurt.num = 1800
            bowlingComponent.hitEvent[0] = hurt

@warning_ignore("unused_parameter")
func Bowling(character: TowerDefenseCharacter) -> void :
    if magnetComponent.breakDownArmor:
        magnetComponent.BreakDownOver()

@warning_ignore("unused_parameter")
func Destroy(freeInsance: bool = true) -> void :
    magnetComponent.Destroy()
    super.Destroy(freeInsance)


func ExportVariantSave() -> Dictionary:
    return {
        "hitArmor": hitArmor, 
        "isDraw": isDraw, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    hitArmor = data.get("hitArmor", false)
    isDraw = data.get("isDraw", false)
