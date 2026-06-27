@tool
extends TowerDefenseZombieGargantuarBase

const ZOMBIE_GARGANTUAR_HEAD_2 = preload("uid://cfx6iqy08xujv")

const ZOMBIE_GARGANTUAR_DUCKXING = preload("uid://6dy81rx4gaue")
const ZOMBIE_GARGANTUAR_ZOMBIE = preload("uid://dtrl03qm2d0u7")

var over: bool = false

const TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM = preload("uid://bto1eksfijahm")

@onready var fireComponent: FireComponent = %FireComponent
@onready var attackComponent2: AttackComponent = %AttackComponent2

@onready var collisionShape: CollisionShape2D = %CollisionShape

@export var fireInterval: float = 3.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval
        attackComponent2.attackInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Gloom":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75
    var randWeapon = randf()
    if randWeapon < 0.3:
        sprite.SetReplace("Zombie_gargantuar_telephonepole.png", ZOMBIE_GARGANTUAR_DUCKXING)
    elif randWeapon < 0.6:
        sprite.SetReplace("Zombie_gargantuar_telephonepole.png", ZOMBIE_GARGANTUAR_ZOMBIE)

    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliter("Zombie_duckytube", true)

    if !TowerDefenseManager.GetMapIsNight():
        fireComponent.timeScale *= 0.5
        walkSpeedScale *= 0.5
    else:
        fireComponent.timeScale *= 1.0
        walkSpeedScale *= 1.0

    attackComponent2.attackReady.connect(_on_attack_component2_ready)
    attackComponent2.attackOver.connect(_on_attack_component2_over)
    fireComponent.fireReady.connect(_on_fire_component_ready)
    fireComponent.fireOver.connect(_on_fire_component_over)

func _on_attack_component2_ready() -> void :
    componentRunning = true

func _on_attack_component2_over() -> void :
    componentRunning = false

func _on_fire_component_ready() -> void :
    componentRunning = true

func _on_fire_component_over() -> void :
    componentRunning = false

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    attackComponent2.attackInterval = fireInterval

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            sprite.SetReplace("Zombie_gargantuar_head.png", ZOMBIE_GARGANTUAR_HEAD_2)

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        impFireEvent:
            sprite.puffShroomImpHead.visible = false

func InWater() -> void :
    super.InWater()
    sprite.SetFliter("Zombie_whitewater", true)

func OutWater() -> void :
    super.OutWater()
    sprite.SetFliter("Zombie_whitewater", false)

func GloompultAttack() -> void :
    var effect = TOWER_DEFENSE_PROJECTILE_EFFECT_GROOM.instantiate()
    effect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    effect.global_position = global_position
    characterNode.add_child(effect)

func DieEntered() -> void :
    super.DieEntered()
    sprite.puffShroomImpHead.visible = false

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantGloompult")
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
                MultiPlayerManager.SendSpawnCharacterAt("PlantGloompult", gridPos.x, gridPos.y, _sync_id)
    Destroy()
