@tool
extends TowerDefenseZombie

@onready var tanglekelpComponent: TanglekelpComponent = %TanglekelpComponent

func _ready() -> void :
    super._ready()
    sprite.animeStarted.connect(AnimeStarted)

func AttackEntered() -> void :
    super.AttackEntered()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

func AttackExited() -> void :
    super.AttackExited()
    if inWater:
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

func InWater() -> void :
    super.InWater()
    tanglekelpComponent.alive = true
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER




func OutWater() -> void :
    tanglekelpComponent.alive = false
    groundHeight = -100
    z = -100
    super.OutWater()
    var tween = create_tween()
    tween.tween_property(sprite, ^"offset", Vector2(-50, -80), 0.25)
    global_position.x -= scale.x * transformPoint.scale.x * 30.0
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM | TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER

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

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            tanglekelpComponent.alive = false
            sprite.head.visible = false


func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantTanglekelp")
    if cell.CanPacketPlant(packetConfig):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos)
        character.WeakUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantTanglekelp", gridPos.x, gridPos.y, _sync_id)
    Destroy()

@warning_ignore("unused_parameter")
func DragBegin(_target: TowerDefenseCharacter) -> void :
    spritePause = true
