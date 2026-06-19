
class_name GroundMoveComponent extends ComponentBase


@export var groundNode: Node2D

var groundPosInit: bool = false

var groundPosSave: Vector2 = Vector2.ZERO


var delay: float = 0.2

var parent: TowerDefenseCharacter


func GetName() -> String:
    return "GroundMoveComponent"


func _ready():
    alive = false
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    if groundNode:
        if groundNode is AdobeAnimateSlot:
            groundNode.updateAllFrame = true
            var sprite = groundNode.get_parent() as AdobeAnimateSprite
            sprite.animeCompleted.connect(GroundNodeAnimationCompleted)
            sprite.animeBlendCompleted.connect(GroundNodeAnimationCompleted)


func _physics_process(delta: float) -> void :
    if !groundNode:
        return
    if alive && !parent.sprite.pause && !parent.sprite.blend:
        if delay <= 0:
            if !groundPosInit:
                groundPosSave = groundNode.position
                groundPosInit = true
            else:
                parent.global_position.x += GetMoveLength().x
                groundPosSave = groundNode.position
        else:
            delay -= delta
            groundPosSave = Vector2.ZERO
            groundPosInit = false
    else:
        groundPosSave = Vector2.ZERO
        groundPosInit = false



func GetMoveLength() -> Vector2:
    return (groundPosSave - groundNode.position) * parent.spriteGroup.scale.x * parent.scale.x * parent.sprite.scale


@warning_ignore("unused_parameter")
func GroundNodeAnimationCompleted(clip: String) -> void :
    groundPosSave = Vector2.ZERO
    groundPosInit = false
