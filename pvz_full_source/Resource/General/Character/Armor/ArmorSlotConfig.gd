@tool
class_name ArmorSlotConfig
extends Resource

@export var armorName: String = ""
@export_enum("Media", "Sprite") var replaceMethod: String = "Media"
@export var replaceMediaName: StringName
@export var slotPath: NodePath
@export var offset: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export_multiline var openFliter: String:
    set(_openFliter):
        openFliter = _openFliter
        emit_changed()
@export_multiline var closeFliter: String:
    set(_closeFliter):
        closeFliter = _closeFliter
        emit_changed()
@export_multiline var destroyFliter: String:
    set(_destroyFliter):
        destroyFliter = _destroyFliter
        emit_changed()
@export var damagePoint: float = -1.0
