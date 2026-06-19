extends Area2D

@onready var collisionShape: CollisionShape2D = %CollisionShape2D

func AreaEntered(area: Area2D) -> void :
    var character = area.get_parent()
    if character is TowerDefenseCharacter:
        if character.sprite.invisible:
            character.sprite.invisible = false
