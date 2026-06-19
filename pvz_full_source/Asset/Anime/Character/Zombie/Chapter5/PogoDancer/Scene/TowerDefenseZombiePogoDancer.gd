@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2

var isJump: bool = false

var hasPogo: bool = true:
    set(_hasPogo):
        hasPogo = _hasPogo
        if !hasPogo:
            idleAnimeClip = "Walk"

var pogoPlant: bool = false
var jumpToPos: float
var jumpWait: int = 1

var walkTime: int = 2
var danceTime: int = 3

var jackson: TowerDefenseCharacter
var _pending_jackson_name: String = ""

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    ySpeed = -300
    if TowerDefenseManager.GetMapIsChess():
        timeScaleInit *= 2

func Walk() -> void :
    if hasPogo:
        state.send_event("ToPogo")
    else:
        state.send_event("ToWalk")

func PogoEntered() -> void :
    sprite.SetAnimation("Pogo", true, 0.2)

@warning_ignore("unused_parameter")
func PogoProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if !pogoPlant:
        if !sprite.pause:
            if global_position.x > groundRight:
                global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * 2.0 * (-1 if sprite.playBack else 1)
            else:
                global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
        if !sprite.pause && attackComponent.CanAttack():
            pogoPlant = true
            jumpToPos = global_position.x - TowerDefenseManager.GetMapGridSize().x * scale.x - 10 * scale.x


    else:
        if isJump:
            if attackComponent2.CanAttack():
                if is_instance_valid(attackComponent2.target):
                    if attackComponent2.target.instance.height >= TowerDefenseEnum.CHARACTER_HEIGHT.TALL:
                        instance.ArmorDelete("Pogo")
                        hasPogo = false
                        isJump = false
                        AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
                        Walk()

func PogoExited() -> void :
    pass

func DanceEntered() -> void :
    danceTime = 3
    sprite.scale.x = -1.0
    sprite.SetAnimation("ArmRise", true, 0.2)

@warning_ignore("unused_parameter")
func DanceProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if !sprite.pause && attackComponent.CanAttack():
        Attack()

func DanceExited() -> void :
    sprite.scale.x = 1.0

func PointEntered() -> void :
    sprite.SetAnimation("PointUp", false, 0.2)
    sprite.AddAnimation("PointDown", 0.75, false, 0.2)

@warning_ignore("unused_parameter")
func PointProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func PointExited() -> void :
    pass

func WalkEntered() -> void :
    super.WalkEntered()
    sprite.scale.x = 1.0
    walkTime = 2

func WalkProcessing(delta: float) -> void :
    if is_instance_valid(jackson):
        groundMoveComponent.alive = jackson.groundMoveComponent.alive
    else:
        groundMoveComponent.alive = true
    super.WalkProcessing(delta)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Walk":
            if (TowerDefenseManager.currentControl && !TowerDefenseManager.currentControl.isGameRunning):
                return
            walkTime -= 1
            if ( !die && !nearDie):
                if walkTime <= 0:
                    if !is_instance_valid(jackson) || (is_instance_valid(jackson) && !jackson.groundMoveComponent.alive):
                        state.send_event("ToDance")
            else:
                OutJackson()
                Die()
        "ArmRise":
            sprite.scale.x = - sprite.scale.x
            danceTime -= 1
            if ( !die && !nearDie):
                if danceTime <= 0:
                    if !is_instance_valid(jackson) || (is_instance_valid(jackson) && !jackson.groundMoveComponent.alive):
                        Walk()
            else:
                OutJackson()
                Die()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Pogo":
            instance.unUseBuffFlags = 0
            isJump = false
            hasPogo = false
            Walk()

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    OutJackson()

func OutJackson() -> void :
    if is_instance_valid(jackson):
        if !jackson.instance.hypnoses:
            jackson.RemoveDancer(self)
        jackson = null

func ExportVariantSave() -> Dictionary:
    var data: Dictionary = {}
    if is_instance_valid(jackson):
        data["jacksonNodeName"] = jackson.name
    data["hasPogo"] = hasPogo
    data["isJump"] = isJump
    data["pogoPlant"] = pogoPlant
    data["jumpToPos"] = jumpToPos
    data["jumpWait"] = jumpWait
    return data

func ImportVariantSave(data: Dictionary) -> void :
    if data.has("jacksonNodeName"):
        _pending_jackson_name = data["jacksonNodeName"]
    hasPogo = data.get("hasPogo", true)
    isJump = data.get("isJump", false)
    pogoPlant = data.get("pogoPlant", false)
    jumpToPos = data.get("jumpToPos", 0.0)
    jumpWait = data.get("jumpWait", 1)

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if _pending_jackson_name != "":
        var _characterNode = TowerDefenseManager.GetCharacterNode()
        if is_instance_valid(_characterNode):
            var node = _characterNode.get_node_or_null(_pending_jackson_name)
            if is_instance_valid(node):
                jackson = node
        _pending_jackson_name = ""

func OutWater() -> void :
    super.OutWater()
    if !hasPogo:
        return
    ySpeed = -300

func Land() -> void :
    if !hasPogo:
        return
    isJump = false
    gravity = 490
    ySpeed = -300
    if pogoPlant:
        isJump = true
        if jumpWait > 0:
            jumpWait -= 1
        else:
            jumpWait = 1
            var tween = create_tween()
            tween.set_ease(Tween.EASE_IN_OUT)
            tween.set_trans(Tween.TRANS_SINE)
            tween.tween_property(self, ^"global_position:x", jumpToPos, 0.5)
            ySpeed = -400
            await tween.finished
            pogoPlant = false
        await get_tree().create_timer(0.2, false).timeout
        isJump = false

func CanBlock() -> bool:
    return hasPogo

func BlockType() -> String:
    return "Jump"

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    instance.ArmorDelete("Pogo")
    hasPogo = false
    isJump = false
    AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
    Walk()
