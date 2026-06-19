@tool
extends TowerDefenseZombie

const DIGGER_RISING_DIRT = preload("uid://bjev0ulao283j")

var speed: float = 50.0

var digOver: bool = false

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    fireComponent.fireInterval = fireInterval

func DigEntered() -> void :
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND
    sprite.SetAnimation("Dig", true, 0.0)
    sprite.head.visible = false

@warning_ignore("unused_parameter")
func DigProcessing(delta: float) -> void :
    shadowSprite.visible = false
    if attackComponent.CanAttack():
        if !nearDie && !sprite.pause && sprite.timeScale > 0 && useAttackDps:
            attackComponent.AttackDps(delta, config.attack)
    elif !sprite.pause:
        if global_position.x > TowerDefenseManager.GetMapGroundRight():
            global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * 2.0 * (-1 if sprite.playBack else 1)
        else:
            global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * (-1 if sprite.playBack else 1)
    sprite.timeScale = timeScale * 1.0

    if !digOver:
        if global_position.x < TowerDefenseManager.GetMapGroundLeft() + 30:
            digOver = true
            state.send_event("ToDrill")
            instance.ArmorDelete("Pick")
            if !instance.hypnoses:
                scale.x = - scale.x

func DigExited() -> void :
    instance.unUseBuffFlags = 0

func DrillEntered() -> void :
    sprite.head.visible = true
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GRIDITEM
    shadowSprite.visible = !invisible
    CreateEffect()
    Rise(0.5, 0.0, false, false)
    sprite.SetAnimation("Drill2", true, 0.2)

@warning_ignore("unused_parameter")
func DrillProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func DrillExited() -> void :
    pass

func LandEntered() -> void :
    sprite.SetAnimation("Land", false, 0.0)
    sprite.AddAnimation("Dizzy", 0.0, false, 0.2)

@warning_ignore("unused_parameter")
func LandProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func LandExited() -> void :
    pass

func Walk() -> void :
    if digOver:
        state.send_event("ToWalk")
    else:
        state.send_event("ToDig")

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Drill2":
            state.send_event("ToLand")
        "Dizzy":
            Walk()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Pick":
            if !digOver:
                digOver = true
                state.send_event("ToDrill")

func CreateEffect() -> void :
    var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(DIGGER_RISING_DIRT, gridPos)
    effect.global_position = shadowSprite.global_position - Vector2(15, 0)
    characterNode.add_child(effect)

@warning_ignore("unused_parameter")
func BlockDigger(target: TowerDefenseCharacter) -> void :
    digOver = true
    state.send_event("ToDrill")

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))
            fireComponent.alive = false

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantGatlingPea")
    if cell.CanPacketPlant(packetConfig, true):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos, true, true)
        character.WeakUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantGatlingPea", gridPos.x, gridPos.y, _sync_id)
    Destroy()
