@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var fireParticles: GPUParticles2D = %FireParticles

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent2.attackInterval = fireInterval

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    checkShape.shape.b.x = - TowerDefenseManager.GetMapGridSize().x * 4.5
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

func FumeShroomAttack() -> void :
    fireParticles.restart()
    AudioManager.AudioPlay("Fume", AudioManagerEnum.TYPE.SFX)
    attackComponent2.AttackEventExecute()

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantFumeShroom")
    if cell.CanPacketPlant(packetConfig):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos)
        character.WakeUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantFumeShroom", gridPos.x, gridPos.y, _sync_id)
    Destroy()
