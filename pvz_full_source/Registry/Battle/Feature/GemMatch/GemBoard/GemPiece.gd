class_name GemPiece extends Node2D

var gridPos: Vector2i = Vector2i(-1, -1)
var characterKey: StringName = ""
var character: TowerDefenseCharacter = null
var isAnimating: bool = false
var isHole: bool = false

func Setup(_gridPos: Vector2i, _characterKey: StringName) -> void :
    gridPos = _gridPos
    characterKey = _characterKey

func SetGridPos(pos: Vector2i) -> void :
    gridPos = pos

func SetAsHole() -> void :
    isHole = true
    characterKey = ""
    character = null

    var rect: ColorRect = ColorRect.new()
    rect.color = Color(0.2, 0.15, 0.1, 0.7)
    rect.size = Vector2(60, 60)
    rect.position = Vector2(-30, -30)
    add_child(rect)

func PlayRemoveAnimation() -> void :
    isAnimating = true
    var tween: Tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
    tween.tween_callback(queue_free)

func PlayFallAnimation(targetPos: Vector2, speed: float) -> void :
    isAnimating = true
    var distance: float = global_position.distance_to(targetPos)
    var duration: float = maxf(distance / speed, 0.15)
    var tween: Tween = create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "global_position", targetPos, duration)
    tween.tween_callback( func() -> void : isAnimating = false)
