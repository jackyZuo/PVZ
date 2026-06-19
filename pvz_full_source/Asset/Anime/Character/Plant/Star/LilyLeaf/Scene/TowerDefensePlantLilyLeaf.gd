@tool
extends TowerDefensePlant

@onready var collisionShape: CollisionShape2D = %CollisionShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 4
    add_to_group("LilyLeaf")

    if get_tree().get_node_count_in_group("LilyLeaf") >= 4:
        var screenEffect = TowerDefenseManager.GetScreenEffectFeature()
        if screenEffect && !screenEffect.HasScreenEffect("Rain"):
            screenEffect.AddScreenEffect("Rain")

func BlockCharacter() -> void :
    itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.EFFECT
    sprite.SetAnimation("Block", false, 0.1)
    sprite.AddAnimation("Idle", 0.0, true, 0.0)

    var screenEffect = TowerDefenseManager.GetScreenEffectFeature()
    if screenEffect && screenEffect.HasScreenEffect("Rain"):
        if randf() < 0.2:
            SpawnPacket(TowerDefenseManager.GetPacketConfig("PlantBYWZ"), spriteGroup.global_position, 15, false)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Block":
            itemLayer = TowerDefenseEnum.LAYER_GROUNDITEM.PLANT_AIR
