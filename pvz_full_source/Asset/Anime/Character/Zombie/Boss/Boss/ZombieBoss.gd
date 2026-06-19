@tool
extends AdobeAnimateSpriteBase

const _EFFECT_FLAGS: Dictionary = {
    "ash": 1, "iceSpeedDown": 2, "cover": 4, "hypnoses": 8, 
    "imitater": 16, "redHeat": 32, "puzzle": 64, "poisoning": 128, "blink": 256, 
}

func _SetEffectFlag(_material: ShaderMaterial, effect: String, enable: bool) -> void :
    if !_material || !_EFFECT_FLAGS.has(effect):
        return
    var flag: int = _EFFECT_FLAGS[effect]
    var current: int = _material.get_shader_parameter("effectFlags") if _material.get_shader_parameter("effectFlags") != null else 0
    if enable:
        current |= flag
    else:
        current &= ~ flag
    _material.set_shader_parameter("effectFlags", current)

const ZOMBIE_BOSS_FOOT = preload("uid://bdbupeo1kkd7d")
const ZOMBIE_BOSS_FOOT_DAMAGE_1 = preload("uid://vbdobkdjpwic")
const ZOMBIE_BOSS_FOOT_DAMAGE_2 = preload("uid://bxr020w2fk7fi")
const ZOMBIE_BOSS_HEAD = preload("uid://ddgj4hhdypirc")
const ZOMBIE_BOSS_HEAD_DAMAGE_1 = preload("uid://bistnk5e5ich0")
const ZOMBIE_BOSS_HEAD_DAMAGE_2 = preload("uid://n6qcrrr2iqyw")
const ZOMBIE_BOSS_JAW = preload("uid://cvmt8yntwyee2")
const ZOMBIE_BOSS_JAW_DAMAGE_1 = preload("uid://b2ibuq3l2d88")
const ZOMBIE_BOSS_JAW_DAMAGE_2 = preload("uid://b4itn6id22yng")
const ZOMBIE_BOSS_OUTERARM_HAND = preload("uid://mtflhdketp20")
const ZOMBIE_BOSS_OUTERARM_HAND_DAMAGE_1 = preload("uid://chkeflw55rmbb")
const ZOMBIE_BOSS_OUTERARM_HAND_DAMAGE_2 = preload("uid://vy3cx0ve4nj2")
const ZOMBIE_BOSS_MOUTHGLOW_BLUE = preload("uid://be7738v73ubqv")
const ZOMBIE_BOSS_MOUTHGLOW_RED = preload("uid://brurgq42t6w1w")
const ZOMBIE_BOSS_EYEGLOW_BLUE = preload("uid://ccbl4l65yrfi")
const ZOMBIE_BOSS_EYEGLOW_RED = preload("uid://lhbwiqkj1nh2")

@onready var driver: AdobeAnimateSpriteBase = %Driver
@onready var arm: AdobeAnimateSpriteBase = %Arm
@onready var armNode: Node2D = %ArmNode
@onready var rv: AdobeAnimateSpriteBase = %RV
@onready var rvNode: Node2D = %RVNode

@onready var headSprite: Sprite2D = %HeadSprite

@onready var headSmoke1: GPUParticles2D = %HeadSmoke1
@onready var headSmoke2: GPUParticles2D = %HeadSmoke2
@onready var headSmoke3: GPUParticles2D = %HeadSmoke3

@onready var spawnMarker: Marker2D = %SpawnMarker
@onready var ballSpawnMarker: Marker2D = %BallSpawnMarker

var armTween: Tween
var headTween: Tween

func _ready() -> void :
    super._ready()
    headSprite.material = headSprite.material.duplicate(true)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    arm.frameIndex = frameIndex
    arm.elapsedTimer = elapsedTimer
    rv.frameIndex = frameIndex
    rv.elapsedTimer = elapsedTimer
    driver.pause = pause

func SetClip(_clip: String) -> void :
    super.SetClip(_clip)
    if is_instance_valid(arm):
        arm.SetClip(_clip)
    if is_instance_valid(rv):
        rv.SetClip(_clip)

func SetSpawn(line: int = 1, time = 0.5) -> void :
    var armOffset: float = TowerDefenseManager.GetMapGridSize().y * (line - (floor(float(TowerDefenseManager.GetMapGridNum().y) / 2) - 1))
    SetArmOffset(armOffset, time)

func SetHeadAttack(line: int = 4, time = 1.0) -> void :
    var headOffset: float = TowerDefenseManager.GetMapGridSize().y * (line - (floor(float(TowerDefenseManager.GetMapGridNum().y) / 2) + 2))
    SetHeadOffset(headOffset, time)
    SetSpawn(line - (floor(float(TowerDefenseManager.GetMapGridNum().y) / 2) + 1), time)

func SetRVPos(gridPos: Vector2i) -> void :
    var _offset = TowerDefenseManager.GetMapGridSize() * Vector2(Vector2(gridPos) - Vector2(1, 2)) - Vector2(0, 100)
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    var height = 0
    if is_instance_valid(cell):
        height = cell.GetGroundHeight(0.0)
    SetRVOffset(_offset - Vector2(0, height), 0.2)

func SetHeadAttackBall(isFire: bool) -> void :
    if isFire:
        SetReplace("Zombie_boss_mouthglow_red.png", ZOMBIE_BOSS_MOUTHGLOW_RED)
        SetReplace("Zombie_boss_eyeglow_red.png", ZOMBIE_BOSS_EYEGLOW_RED)
    else:
        SetReplace("Zombie_boss_mouthglow_red.png", ZOMBIE_BOSS_MOUTHGLOW_BLUE)
        SetReplace("Zombie_boss_eyeglow_red.png", ZOMBIE_BOSS_EYEGLOW_BLUE)

func DamagePointSet(damagePointName: String) -> void :
    match damagePointName:
        "Stage1":
            SetReplace("Zombie_boss_head.png", ZOMBIE_BOSS_HEAD_DAMAGE_1)
            SetReplace("Zombie_boss_jaw.png", ZOMBIE_BOSS_JAW_DAMAGE_1)
            SetReplace("Zombie_boss_foot_inner.png", ZOMBIE_BOSS_FOOT_DAMAGE_1)
            arm.SetReplace("Zombie_boss_outerarm_hand.png", ZOMBIE_BOSS_OUTERARM_HAND_DAMAGE_1)
            headSprite.texture = ZOMBIE_BOSS_HEAD_DAMAGE_1
        "Stage2":
            SetReplace("Zombie_boss_head.png", ZOMBIE_BOSS_HEAD_DAMAGE_2)
            SetReplace("Zombie_boss_jaw.png", ZOMBIE_BOSS_JAW_DAMAGE_2)
            SetReplace("Zombie_boss_foot.png", ZOMBIE_BOSS_FOOT_DAMAGE_2)
            arm.SetReplace("Zombie_boss_outerarm_hand.png", ZOMBIE_BOSS_OUTERARM_HAND_DAMAGE_2)
            headSprite.texture = ZOMBIE_BOSS_HEAD_DAMAGE_2
            headSmoke1.visible = true
            headSmoke2.visible = true
        "Stage3":
            _SetEffectFlag(material, "blink", true)
            _SetEffectFlag(arm.material, "blink", true)
            _SetEffectFlag(headSprite.material, "blink", true)
            headSmoke3.visible = true
        "Death":
            driver.timeScale = 1.5
            driver.SetAnimation("Death", false, 0.2)
            driver.AddAnimation("Flag", 0.0, false, 0.0)
            driver.AddAnimation("FlagLoop", 0.0, true, 0.0)
            _SetEffectFlag(material, "blink", false)
            _SetEffectFlag(arm.material, "blink", false)
            _SetEffectFlag(headSprite.material, "blink", false)
            headSmoke1.visible = false
            headSmoke2.visible = false
            headSmoke3.visible = false

func SetArmOffset(_offset: float, time = 0.5) -> void :
    if is_instance_valid(armTween):
        if armTween.is_running():
            armTween.kill()
    armTween = create_tween()
    armTween.set_ease(Tween.EASE_OUT)
    armTween.set_trans(Tween.TRANS_LINEAR)
    armTween.tween_property(armNode, ^"position:y", _offset, time)

func SetHeadOffset(_offset: float, time = 1.0) -> void :
    if is_instance_valid(headTween):
        if headTween.is_running():
            headTween.kill()
    headTween = create_tween()
    headTween.set_ease(Tween.EASE_OUT)
    headTween.set_trans(Tween.TRANS_LINEAR)
    headTween.tween_property(self, ^"offset:y", -300 + _offset, time)

func SetRVOffset(_offset: Vector2, time = 0.2) -> void :
    if is_instance_valid(headTween):
        if headTween.is_running():
            headTween.kill()
    headTween = create_tween()
    headTween.set_ease(Tween.EASE_OUT)
    headTween.set_trans(Tween.TRANS_LINEAR)
    headTween.tween_property(rvNode, ^"position", _offset, time)

func SetRVVisible(_visible: bool) -> void :
    rvNode.visible = _visible
    SetFliters(["Boss_RV", "Boss_RV_wheel1", "Boss_RV_wheel2"], !_visible)

func AnimeCompleted(_clip: String) -> void :
    match _clip:
        "Spawn1":
            SetSpawn(1)
        "RV":
            SetRVVisible(false)
            rvNode.position = Vector2.ZERO
