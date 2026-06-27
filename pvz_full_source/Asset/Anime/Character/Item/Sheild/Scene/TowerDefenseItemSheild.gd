@tool
class_name TowerDefenseItemSheild extends TowerDefenseItem


const MAX_LAYERS: int = 8
const HP_PER_LAYER: float = 1000.0
const MAX_HP: float = 8000.0


@export var shieldType: StringName = &"Default"


@onready var _layerLabel: Label = %LayerLabel

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return


    instance.canBeCollection = true

    _ShieldUpdateLabel()


func _ShieldUpdateLabel() -> void :
    if !is_instance_valid(_layerLabel):
        return
    _layerLabel.text = str(int(instance.hitpoints))


func ShieldGetLayerCount() -> int:
    return clampi(int(instance.hitpoints / HP_PER_LAYER), 0, MAX_LAYERS)




func ShieldAddHitpoints(num: float, newShieldType: StringName = &"Default") -> void :
    if num <= 0:
        return
    instance.hitpoints = minf(instance.hitpoints + num, MAX_HP)

    if shieldType != newShieldType:
        shieldType = newShieldType
        _ShieldUpdateAppearance()
    _ShieldUpdateLabel()



func ShieldAbsorbDamage(num: float) -> float:
    if num <= 0 || instance.hitpoints <= 0:
        return num
    var _absorbed: float = minf(num, instance.hitpoints)
    instance.hitpoints -= _absorbed
    _ShieldUpdateLabel()
    if instance.hitpoints <= 0:
        instance.hitpoints = 0
        instance.hitpointsEmpty.emit()
    return num - _absorbed




func ShieldBlockLethal() -> bool:
    if instance.hitpoints <= 0:
        return false
    var _consume: float = minf(HP_PER_LAYER, instance.hitpoints)
    instance.hitpoints -= _consume
    _ShieldUpdateLabel()
    if instance.hitpoints <= 0:
        instance.hitpoints = 0
        instance.hitpointsEmpty.emit()
    return true


func ShieldBlockCharm() -> bool:
    return ShieldBlockLethal()



func ShieldDeflateVehicle(attacker: TowerDefenseCharacter) -> void :
    if !is_instance_valid(attacker):
        return
    if attacker is TowerDefenseZombie:
        if attacker.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.CAR:
            attacker.Destroy()


func _ShieldUpdateAppearance() -> void :


    pass





static func CreateOnCell(cell: TowerDefenseCellInstance, newShieldType: StringName = &"Default", layers: int = 1) -> void :
    CreateOnCellWithHP(cell, newShieldType, layers * HP_PER_LAYER)





static func CreateOnCellWithHP(cell: TowerDefenseCellInstance, newShieldType: StringName, hp: float) -> void :
    if !is_instance_valid(cell):
        return

    if is_instance_valid(cell.itemShield):
        cell.itemShield.ShieldAddHitpoints(hp, newShieldType)
        return

    var _packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ItemSheild")
    if !_packetConfig:
        return
    var _character: TowerDefenseCharacter = _packetConfig.Plant(cell.gridPos, false, true)
    if _character is TowerDefenseItemSheild:
        _character.shieldType = newShieldType
        _character.instance.hitpoints = minf(hp, MAX_HP)
        _character._ShieldUpdateLabel()
