@tool
class_name TowerDefenseZombie extends TowerDefenseCharacter

var waterInteractionComponent: WaterInteractionComponent
var groundMoveComponent: GroundMoveComponent
var attackComponent: AttackComponent
var garlicComponent: GarlicComponent
var swimComponent: SwimComponent
var zombieDeathComponent: ZombieDeathComponent

@export var groan: String
@export var walkSpeedScale: float = 1.0
@export var inSwimAnimeClipScale: float = 1.0
@export var useAttackDps: bool = true

@export var walkAnimeClip: String = "Walk"
@export var inSwimAnimeClip: String = ""
@export var swimAnimeClip: String = "Walk"
@export var outSwimAnimeClip: String = ""
@export var attackAnimeClip: String = "Eat"
@export var attackWaterAnimeClip: String = ""
@export var dieAnimeClip: String = "Death"
@export var dieWaterAnimeClip: String = "Death"
@export var duckytobeSprite: AdobeAnimateSprite
@export var waterLineSprite: AdobeAnimateSprite
@export_multiline var waterAnimeFliter: String = ""
@export var garlicFliters: Array[String] = ["anim_head2", "anim_tongue"]
@export var garlicReplace: String = "Zombie_head.png"

@export var waterHeight: float = 25

func OnRiseStart() -> void :
    Idle()
    attackComponent.alive = false

func OnRiseEnd() -> void :
    Walk()
    attackComponent.alive = true

var isPause: bool = false:
    set(_isPause):
        isPause = _isPause
        if !is_node_ready():
            await ready
        if isPause:
            sprite.pause = true
            state.process_mode = Node.PROCESS_MODE_DISABLED
            hitBox.process_mode = Node.PROCESS_MODE_DISABLED
            set_physics_process(false)
            groundHeightComponent.alive = false
        else:
            sprite.pause = false
            state.process_mode = Node.PROCESS_MODE_INHERIT
            hitBox.process_mode = Node.PROCESS_MODE_INHERIT
            set_physics_process(true)
            groundHeightComponent.alive = true

var isGarlic: bool = false
var isGarlicBird: bool = false
var isChangeLine: bool = false
var inSwimPlay: bool = false
var inGround: bool = false
var startAttack: bool = false
var sizeUpNum: int = 2
var hasGhost: bool = false
var ghostCharacter: TowerDefenseZombie = null
var hasSpikeball: bool = false

var rect: Rect2

var spritePause: bool = false

var _gridSize: Vector2
var _dieClipArray: PackedStringArray = PackedStringArray()
var _dieWaterClipArray: PackedStringArray = PackedStringArray()

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if is_instance_valid(componentManager):
        waterInteractionComponent = componentManager.GetComponentFromType("WaterInteractionComponent")
        groundMoveComponent = componentManager.GetComponentFromType("GroundMoveComponent")
        attackComponent = componentManager.GetComponentFromType("AttackComponent")
        garlicComponent = componentManager.GetComponentFromType("GarlicComponent")
        swimComponent = componentManager.GetComponentFromType("SwimComponent")
        zombieDeathComponent = componentManager.GetComponentFromType("ZombieDeathComponent")
        if is_instance_valid(waterInteractionComponent):
            waterInteractionComponent.shadowComponent = shadowComponent
        if is_instance_valid(groundHeightComponent) && is_instance_valid(waterInteractionComponent):
            groundHeightComponent.waterInteractionComponent = waterInteractionComponent
    if dieAnimeClip != "":
        _dieClipArray = dieAnimeClip.split("&", false)
    if dieWaterAnimeClip != "":
        _dieWaterClipArray = dieWaterAnimeClip.split("&", false)
    rect = get_viewport().get_visible_rect()
    if !(Global.isMultiplayerMode and !MultiPlayerManager.isHost):
        timeScale += randf_range(-0.1, 0.1)
    add_to_group("Zombie", true)
    if !(Global.isMultiplayerMode and !MultiPlayerManager.isHost):
        walkSpeedScale += walkSpeedScale * randf_range(-0.1, 0.1)
    instance.hitpointsEmpty.connect(Die)

    if is_instance_valid(duckytobeSprite):
        if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
            waterInteractionComponent.inWaterLine = true
            duckytobeSprite.visible = true

    if is_instance_valid(cell) && cell.IsWater() && !(instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
        inWater = true

    _gridSize = TowerDefenseManager.GetMapGridSize()
    showHealthComponent.alive = GameSaveManager.GetConfigValue("ShowZombieHealth")
    BattleEventBus.showZombieHealth.connect(_on_show_zombie_health)

    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        if is_instance_valid(attackComponent):
            attackComponent.alive = false
            attackComponent.set_physics_process(false)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        if sync_id < 0:
            _auto_register_sync.call_deferred()

func _auto_register_sync() -> void :
    if !Global.isMultiplayerMode or !MultiPlayerManager.isHost:
        return
    if sync_id >= 0:
        return
    if !is_instance_valid(self) or isDestroy:
        return
    if isShow:
        return
    var control = TowerDefenseManager.currentControl
    if !is_instance_valid(control):
        return
    var new_sync_id: int = control._get_next_sync_id()
    control._register_sync_character(new_sync_id, self)
    if is_instance_valid(config):
        MultiPlayerManager.SendSpawnCharacterAt(config.name, gridPos.x, gridPos.y, new_sync_id, instance.hitpointScale if is_instance_valid(instance) else 1.0, transformPoint.scale.x, instance.hypnoses if is_instance_valid(instance) else false, 0.0, true, global_position.x, global_position.y)

func _exit_tree() -> void :
    if Engine.is_editor_hint():
        return
    if is_instance_valid(BattleEventBus) && BattleEventBus.showZombieHealth.is_connected(_on_show_zombie_health):
        BattleEventBus.showZombieHealth.disconnect(_on_show_zombie_health)

func _on_show_zombie_health(_show: bool) -> void :
    showHealthComponent.alive = _show

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    sprite.pause = TowerDefenseManager.pauseZombie || spritePause
    sprite.playBack = TowerDefenseManager.backZombie || isGarlicBird
    if TowerDefenseManager.GetMapFeature():
        if is_instance_valid(cell):
            var cellPos: Vector2 = TowerDefenseManager.GetMapCellPos(gridPos)
            var offset: Vector2 = global_position - cellPos
            cellPercentage = offset.x / _gridSize.x
            if inGame:
                if !isPause:
                    pass
        else:
            inWater = false
    if (Engine.get_physics_frames() + randFreshIndex) % 30 == 0:
        if !inGround:
            if global_position.x < groundRight + 150:
                inGround = true
                if inGame:
                    await get_tree().create_timer(randf_range(0.5, 3.0), false).timeout
                    AudioManager.AudioPlay(groan, AudioManagerEnum.TYPE.SFX)
        if scale.x < 0:
            if global_position.x > groundRight + 150:
                if !(Global.isMultiplayerMode and !MultiPlayerManager.isHost):
                    Destroy()
        if scale.x > 0:
            if global_position.x < TowerDefenseManager.GetMapGroundLeft() - 150:
                if !(Global.isMultiplayerMode and !MultiPlayerManager.isHost):
                    Destroy()

        if inWater:
            InWaterDiscardSet()
        else:
            OutWaterDiscardSet()



@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if isRise:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    sprite.timeScale = timeScale
    if attackComponent.CanAttack():
        Attack()

func GarlicEntered() -> void :
    pass

@warning_ignore("unused_parameter")
func GarlicProcessing(delta: float) -> void :
    sprite.timeScale = 0.0

func GarlicExited() -> void :
    pass

func WalkEntered() -> void :
    swimComponent.WalkEntered()
    if is_instance_valid(get_tree()):
        await get_tree().create_timer(0.1, false).timeout
    groundMoveComponent.alive = true

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    swimComponent.WalkProcessing(delta)
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if !sprite.pause && attackComponent.CanAttack():
        Attack()

func WalkExited() -> void :
    if !instance.die:
        groundMoveComponent.alive = false

func AttackEntered() -> void :
    if inWater && attackWaterAnimeClip != "":
        sprite.SetAnimation(attackWaterAnimeClip, true, 0.2)
    else:
        sprite.SetAnimation(attackAnimeClip, true, 0.2)
    startAttack = false
    await get_tree().create_timer(0.1, false).timeout
    startAttack = true

@warning_ignore("unused_parameter")
func AttackProcessing(delta: float) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if !attackComponent.CanAttack():
        Walk()
    else:
        if startAttack && !nearDie && !sprite.pause && sprite.timeScale > 0 && useAttackDps:
            attackComponent.AttackDps(delta, config.attack)
    sprite.timeScale = timeScale * 2.0

func AttackExited() -> void :
    pass

func DieEntered() -> void :
    zombieDeathComponent.DieEntered()

@warning_ignore("unused_parameter")
func DieProcessing(delta: float) -> void :
    sprite.timeScale = timeScale



func WalkReady() -> void :
    await get_tree().physics_frame
    Walk()

func Walk() -> void :
    if die:
        state.send_event("ToDie")
        return
    state.send_event("ToWalk")

func Attack() -> void :
    if die:
        state.send_event("ToDie")
        return
    state.send_event("ToAttck")

func Die() -> void :
    state.send_event("ToDie")

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    swimComponent.AnimeCompleted(clip)
    if await zombieDeathComponent.AnimeCompleted(clip):
        return
    if die:
        HitBoxDestroy()
        Die()

func Garlic() -> void :
    garlicComponent.Garlic()

func ChangeLine() -> void :
    garlicComponent.ChangeLine()

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES:
        return

    attackComponent.target = null
    if time == -1:
        bodyHurt.emit(GetCurrentHitPoint())

func InWaterDiscardSet() -> void :
    waterInteractionComponent.InWaterDiscardSet()

func OutWaterDiscardSet() -> void :
    waterInteractionComponent.OutWaterDiscardSet()

func InWater() -> void :
    super.InWater()
    swimComponent.InWater()
    waterInteractionComponent.InWater()

func OutWater() -> void :
    super.OutWater()
    waterInteractionComponent.OutWater()
    swimComponent.OutWater()
