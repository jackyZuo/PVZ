class_name TowerDefenseProjectileEffectBase extends Node2D

@export var eventList: Array[TowerDefenseCharacterEventBase]

var gridPos: Vector2i
var camp: TowerDefenseEnum.CHARACTER_CAMP
var collisionFlag: int
var target: TowerDefenseCharacter
var height: float

func Init(_gridPos: Vector2i, _camp: TowerDefenseEnum.CHARACTER_CAMP, _collisionFlag: int, _target: TowerDefenseCharacter, _height = 0.0) -> void :
    gridPos = _gridPos
    camp = _camp
    collisionFlag = _collisionFlag
    target = _target
    height = _height
