class_name WarningLine extends Node2D

@onready var sprite: Sprite2D = %Sprite

var feature: TowerDefenseBattleFeatureWarningLine
var row: int

func _on_area_2d_area_entered(area: Area2D) -> void :
    var character = area.get_parent()
    if !(character is TowerDefenseCharacter):
        return
    if character.config.warnningLineFliter:
        return
    if character.scale.x < 0:
        return
    if character.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        return
    if character.instance.maskFlags & (TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND) || character.instance.maskFlags == 0:
        return
    if character is TowerDefensePlant:
        return
    if character is TowerDefenseZombie:
        if character.instance.die || character.instance.nearDie:
            return
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return
    if feature:
        feature.OnWarningLineTriggered()


func _on_area_2d_2_area_entered(area: Area2D) -> void :
    var character = area.get_parent()
    if !(character is TowerDefenseCharacter):
        return
    if character.config.warnningLineFliter:
        return
    if character.scale.x > 0:
        return
    if character.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        return
    if character.instance.maskFlags & (TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND) || character.instance.maskFlags == 0:
        return
    if character is TowerDefensePlant:
        return
    if character is TowerDefenseZombie:
        if character.instance.die || character.instance.nearDie:
            return
    if feature:
        feature.OnWarningLineTriggered()
