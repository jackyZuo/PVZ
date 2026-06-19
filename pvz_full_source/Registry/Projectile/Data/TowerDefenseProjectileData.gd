@tool
class_name TowerDefenseProjectileData extends Resource

@export var name: String
@export var baseDamage: float = 20
@export var size: Vector2 = Vector2(28, 28)
@export var scale: Vector2 = Vector2(1, 1)

@export var projectileScene: PackedScene
@export var splatAudio: String = "SplatNormal"
@export var splatScene: PackedScene
@export var hitEffect: PackedScene
@export var hitTargetEventList: Array[TowerDefenseCharacterEventBase]
@export var hitCharacterEventList: Array[TowerDefenseCharacterEventBase]
@export var hitGroundEventList: Array[TowerDefenseCharacterEventBase]

@export_group("Init")
@export var blockHurt: float = -1
@export var rotateFollowVelocity: bool = false
@export var rotateScale: float = 0.0
@export var hitBody: bool = false
@export_group("Range")
@export_enum("Default", "Bomb") var rangeType: String = "Default"
@export var useRange: bool = false
@export var rangeSize: Vector2 = Vector2(0.5, 0.5)
@export var hitPesontage: float = 0.25
