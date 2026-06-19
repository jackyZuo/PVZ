@tool
extends TowerDefenseZombie

func _ready() -> void :
    super._ready()
    sprite.animeStarted.connect(AnimeStarted)

func AttackEntered() -> void :
    super.AttackEntered()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

func AttackExited() -> void :
    super.AttackEntered()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

func InWater() -> void :
    super.InWater()
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER




func OutWater() -> void :
    groundHeight = -100
    z = -100
    super.OutWater()
    var tween = create_tween()
    tween.tween_property(sprite, ^"offset", Vector2(-50, -80), 0.25)
    global_position.x -= scale.x * transformPoint.scale.x * 30.0
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM

func DieEntered() -> void :
    super.DieEntered()
    sprite.offset = Vector2(-50, -80)

func AnimeStarted(clip: String) -> void :
    match clip:
        "Swim":
            sprite.offset = Vector2(-10, -100)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Jump":
            instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER
            sprite.offset = Vector2(-10, -100)
            global_position.x -= scale.x * transformPoint.scale.x * 40.0
