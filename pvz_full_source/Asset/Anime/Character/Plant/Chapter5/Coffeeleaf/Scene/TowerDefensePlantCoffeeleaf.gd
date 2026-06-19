@tool
extends TowerDefensePlant

@onready var collisionShape: CollisionShape2D = %CollisionShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 4


func BlockCharacter() -> void :
    itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.EFFECT
    sprite.SetAnimation("Block", false, 0.1)
    sprite.AddAnimation("Idle", 0.0, true, 0.0)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Block":
            itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.PLANT_AIR
