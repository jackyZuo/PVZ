@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2

@export var eventList: Array[TowerDefenseCharacterEventBase] = []

var savePos: Vector2

var halfHp: bool = false
var isAttack: bool = false

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    sprite.head.animeCompleted.connect(AnimeCompleted)

    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if isRise:
        return
    sprite.timeScale = timeScale

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    if global_position.x > TowerDefenseManager.GetMapGroundRight():
        sprite.timeScale = timeScale * walkSpeedScale * 2.0
    else:
        sprite.timeScale = timeScale * walkSpeedScale

    if die || nearDie:
        return

    if !sprite.pause && attackComponent2.CanAttack():
        instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.DYING_CHARACTER
        savePos = attackComponent2.target.global_position



        sprite.head.usePos = false
        sprite.head.useRotate = false
        Idle()
        sprite.head.timeScale = 4.0
        sprite.head.SetAnimation("JumpUp", false, 0.2)
        var tween = create_tween()
        tween.set_parallel(true)
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_QUART)
        tween.tween_property(sprite.head, ^"offsetRotate", 0.0, 0.5)
        tween.tween_property(sprite.head, ^"rotation", 0.0, 0.5)
        tween.tween_property(sprite.head, ^"offset:y", -100.0, 0.5)
        tween.tween_property(sprite.head, ^"offset:x", global_position.x - savePos.x, 0.5)

func AttackEntered():
    super.AttackEntered()
    isAttack = true
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func AttackExited() -> void :
    super.AttackExited()
    isAttack = false
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper", "Zombie_outerarm_hand", "Zombie_outerarm_lower"], false)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            halfHp = true
            sprite.SetFliters(["Zombie_outerarm_upper"], true)
        "Head":
            DamagePartCreate("Head", sprite.head, Vector2(randf_range(-100, 100), -300), false, Vector2(-25, -30))

func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    super.ArmorDamagePointReach(armorName, stage)
    if isAttack && HasShield() && stage > 0:
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "JumpUp":
            await get_tree().create_timer(0.25, false).timeout
            sprite.head.SetAnimation("JumpDown", false, 0.2)

            var tween = create_tween()
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_QUART)
            tween.tween_property(sprite.head, ^"offset:y", 40.0, 0.1)
        "JumpDown":
            if over:
                return
            over = true
            AudioManager.AudioPlay("GargantuarThump", AudioManagerEnum.TYPE.SFX)
            ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
            TowerDefenseExplode.CreateExplode(savePos, Vector2(0.5, 0.2), eventList, [], camp, instance.collisionFlags)
            await get_tree().create_timer(0.5, false).timeout
            Die()
            sprite.head.visible = false

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantSquash")
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
                MultiPlayerManager.SendSpawnCharacterAt("PlantSquash", gridPos.x, gridPos.y, _sync_id)
    Destroy()
