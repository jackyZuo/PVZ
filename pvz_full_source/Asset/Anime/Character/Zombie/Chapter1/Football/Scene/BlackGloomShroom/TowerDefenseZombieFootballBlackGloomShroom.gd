@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2
@onready var collisionShape: CollisionShape2D = %CollisionShape

const TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM = preload("uid://bto1eksfijahm")

@export var fireInterval: float = 2.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent2.attackInterval = fireInterval

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater"], true)
    if !TowerDefenseManager.GetMapIsNight():
        attackComponent2.timeScale *= 0.5
        walkSpeedScale *= 0.5
    else:
        attackComponent2.timeScale *= 1.0
        walkSpeedScale *= 1.0

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 3.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func GloomShroomAttack() -> void :
    var effect = TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM.instantiate()
    effect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    effect.global_position = global_position
    characterNode.add_child(effect)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantGloomShroom")
    if cell.CanPacketPlant(packetConfig, true):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos, true, true)
        character.WakeUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantGloomShroom", gridPos.x, gridPos.y, _sync_id)
    Destroy()
