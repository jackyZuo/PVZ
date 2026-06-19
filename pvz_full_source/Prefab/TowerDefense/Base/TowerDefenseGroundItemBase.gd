@tool
class_name TowerDefenseGroundItemBase extends Node2D

@export var groundHeight: float = 0.0:
    set(_groundHeight):
        if groundHeight != _groundHeight:
            groundHeight = _groundHeight
            if isGround && z != groundHeight:
                z = groundHeight
@export var z: float = 0.0:
    set(_z):
        if z != _z:
            z = _z
            SetZ()
@export var gridPos: Vector2i = Vector2i(-1, -1):
    set(_gridPos):
        if gridPos != _gridPos:
            gridPos = _gridPos
            cell = TowerDefenseManager.GetMapCell(gridPos)
            FreshZIndex()
@export var itemLayer: TowerDefenseEnum.LAYER_GROUNDITEM = TowerDefenseEnum.LAYER_GROUNDITEM.DEFAULT:
    set(_itemLayer):
        itemLayer = _itemLayer
        FreshZIndex()

@export var cell: TowerDefenseCellInstance
@export var cellPercentage: float = 0.5

@export var gravityUse: bool = true
@export var gravity: float = 245.0
@export var gravityScale: float = 1.5
@export var ySpeed: float = 0.0
@export var topLayer: bool = false:
    set(_topLayer):
        topLayer = _topLayer
        FreshZIndex()

signal land()

static var characterNode: Node2D
@warning_ignore("unused_private_class_variable")
static var _tdServer: Node = null

var isGround: bool = true

func _enter_tree() -> void :
    if Engine.is_editor_hint():
        return
    characterNode = TowerDefenseManager.GetCharacterNode()

func _ready() -> void :
    FreshZIndex()

func _physics_process(delta: float) -> void :
    PhysiceUpdate(delta)

func PhysiceUpdate(delta: float) -> void :
    if isGround && ySpeed >= 0:
        if z != groundHeight:
            z = groundHeight
        return
    if z > groundHeight || ySpeed < 0:
        isGround = false
        if gravityUse:
            ySpeed += gravity * gravityScale * delta
        z -= ySpeed * delta
        if z <= groundHeight && ySpeed >= 0:
            land.emit()
            z = groundHeight
            if ySpeed >= 0:
                ySpeed = 0
                isGround = true
    else:
        ySpeed = 0
        z = groundHeight
        isGround = true

func SetZ() -> void :
    pass

func FreshZIndex() -> void :
    if !topLayer:
        z_index = 0 + gridPos.y * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + itemLayer
    else:
        z_index = 0 + 100 * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + itemLayer

func GetFallTime() -> float:
    var t1: float = abs(ySpeed) / (gravity * gravityScale)
    var h = (gravity * gravityScale) * pow(t1, 2) / 2 + (z - groundHeight)
    var t2 = sqrt(2 * h / (gravity * gravityScale))
    return t1 + t2
