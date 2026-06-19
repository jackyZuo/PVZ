
class_name SlotComponent extends ComponentBase


var parent: TowerDefenseCharacter


@export var posMark: Marker2D


@export var heightFollow: bool = false

@export var hideShadow: bool = true


var cell: TowerDefenseCellInstance

var slotCharacter: TowerDefenseCharacter

var surroundCharacter: TowerDefenseCharacter


var slotCharacterShadow: bool = false

var surroundCharacterShadow: bool = false


func GetName() -> String:
    return "SlotComponent"


func _exit_tree() -> void :
    if !is_instance_valid(cell):
        return
    if is_instance_valid(slotCharacter):
        if slotCharacterShadow:
            slotCharacter.shadowSprite.visible = !slotCharacter.invisible
    if is_instance_valid(surroundCharacter):
        if surroundCharacterShadow:
            surroundCharacter.shadowSprite.visible = !surroundCharacter.invisible


func _ready() -> void :
    parent = get_parent().parent
    if TowerDefenseManager.GetMapFeature():
        cell = TowerDefenseManager.GetMapCell(parent.gridPos)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive:
        return
    if parent.die:
        return
    if !is_instance_valid(cell):
        if TowerDefenseManager.GetMapFeature():
            cell = TowerDefenseManager.GetMapCell(parent.gridPos)
        if !is_instance_valid(cell):
            return
    var getSlot: TowerDefenseCharacter = cell.GetSlot(parent)
    if is_instance_valid(slotCharacter) && slotCharacter == getSlot:
        slotCharacter.shadowComponent.followHeight = heightFollow
        slotCharacter.groundHeight = (parent.global_position.y - posMark.global_position.y) / parent.transformPoint.global_scale.y
        slotCharacter.shadowSprite.visible = slotCharacterShadow && !hideShadow && !slotCharacter.invisible
    else:
        slotCharacter = getSlot
        if is_instance_valid(slotCharacter):
            slotCharacter.groundHeight = 0
            slotCharacterShadow = slotCharacter.shadowSprite.visible
            slotCharacter.shadowSprite.visible = slotCharacterShadow && !hideShadow && !slotCharacter.invisible

    var getSurround: TowerDefenseCharacter = cell.GetSurround()
    if is_instance_valid(surroundCharacter) && surroundCharacter == getSurround:
        surroundCharacter.shadowComponent.followHeight = heightFollow
        surroundCharacter.groundHeight = (parent.global_position.y - posMark.global_position.y) / parent.transformPoint.global_scale.y
        surroundCharacter.shadowSprite.visible = surroundCharacterShadow && !hideShadow && !surroundCharacter.invisible
    else:
        surroundCharacter = getSurround
        if is_instance_valid(surroundCharacter):
            surroundCharacter.groundHeight = 0
            surroundCharacterShadow = surroundCharacter.shadowSprite.visible
            surroundCharacter.shadowSprite.visible = surroundCharacterShadow && !hideShadow && !surroundCharacter.invisible
