
class_name ShowHealthComponent extends ComponentBase


@onready var shieldHitpointLabel: Label = %ShieldHitpointLabel

@onready var helmetHitpointLabel: Label = %HelmetHitpointLabel

@onready var bodyHitpointLabel: Label = %BodyHitpointLabel


@onready var centerContainer: CenterContainer = %CenterContainer


@export var parent: TowerDefenseCharacter


var _dirty: bool = true


func GetName() -> String:
    return "ShowHealthComponent"


func _ready() -> void :
    z_index = 10


func MarkDirty() -> void :
    _dirty = true


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive:
        return
    global_transform = Transform2D(0.0, Vector2.ONE, 0.0, global_position)
    if !_dirty:
        return
    _dirty = false
    var _activeShield: TowerDefenseArmorInstance = null
    for _armor: TowerDefenseArmorInstance in parent.instance.armorShield:
        if !_armor.isRemove:
            _activeShield = _armor
            break
    if _activeShield:
        shieldHitpointLabel.visible = true
        shieldHitpointLabel.text = "HP:%d/%d" % [_activeShield.hitPoints, _activeShield.hitpointsSave]
    else:
        shieldHitpointLabel.visible = false

    var _activeHeadCover: TowerDefenseArmorInstance = null
    for _armor: TowerDefenseArmorInstance in parent.instance.armorHeadCover:
        if !_armor.isRemove:
            _activeHeadCover = _armor
            break
    if _activeHeadCover:
        shieldHitpointLabel.visible = true
        shieldHitpointLabel.text = "HP:%d/%d" % [_activeHeadCover.hitPoints, _activeHeadCover.hitpointsSave]

    var _activeHelm: TowerDefenseArmorInstance = null
    for _armor: TowerDefenseArmorInstance in parent.instance.armorHelm:
        if !_armor.isRemove:
            _activeHelm = _armor
            break
    if _activeHelm:
        helmetHitpointLabel.visible = true
        helmetHitpointLabel.text = "HP:%d/%d" % [_activeHelm.hitPoints, _activeHelm.hitpointsSave]
    else:
        helmetHitpointLabel.visible = false

    bodyHitpointLabel.visible = true
    bodyHitpointLabel.text = "HP:%d/%d" % [parent.instance.hitpoints, parent.instance.hitpointsSave]



func SetAlive(_alive: bool) -> void :
    if alive == _alive:
        return
    alive = _alive
    if !is_node_ready():
        await ready
    if !alive:
        shieldHitpointLabel.visible = false
        helmetHitpointLabel.visible = false
        bodyHitpointLabel.visible = false
    else:
        _dirty = true
