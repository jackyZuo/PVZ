@tool
extends TowerDefenseZombie

const QUAKE = preload("uid://dwcqjpnoyit8f")

@onready var attackComponent2: AttackComponent = %AttackComponent2

@export var eventList: Array[TowerDefenseCharacterEventBase]

var isJump: bool = false

var hasPogo: bool = true:
    set(_hasPogo):
        hasPogo = _hasPogo
        if !hasPogo:
            instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
            idleAnimeClip = "Idle"

var pogoPlant: bool = false
var jumpToPos: float
var jumpWait: int = 2

var quake: bool = false

var moveTween: Tween

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
    if isGround:
        ySpeed = -300

@warning_ignore("unused_parameter")
func PogoProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

    if attackComponent.CanAttack():
        if attackComponent.target is TowerDefensePlant:

            if attackComponent.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
                if attackComponent.target.instance.spikeHurt != -1:
                    attackComponent.target.Hurt(min(100.0, attackComponent.target.instance.spikeHurt))
                else:
                    attackComponent.target.Destroy()
                instance.ArmorDelete("Pogo")
                hasPogo = false
                isJump = false
                AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
                Walk()
                return

    if !pogoPlant:
        if !quake:
            if !sprite.pause:
                if global_position.x > groundRight:
                    global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * 2.0 * (-1 if sprite.playBack else 1)
                else:
                    global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
        if !sprite.pause && attackComponent.CanAttack():

            quake = false
            pogoPlant = true
            jumpToPos = global_position.x - TowerDefenseManager.GetMapGridSize().x * scale.x - 10 * scale.x
            if attackComponent2.CanAttack():
                if is_instance_valid(attackComponent2.target):
                    if attackComponent2.target.instance.height >= TowerDefenseEnum.CHARACTER_HEIGHT.TALL:
                        quake = true
                        jumpToPos = global_position.x

func PogoExited() -> void :
    pass

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Pogo":
            instance.unUseBuffFlags = 0
            isJump = false
            hasPogo = false
            Walk()

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
    if attackComponent2.CanAttack():
        if is_instance_valid(attackComponent2.target):
            if attackComponent2.target.instance.height >= TowerDefenseEnum.CHARACTER_HEIGHT.TALL:
                quake = true
    if quake:
        ySpeed = -400
        var flag: bool = false
        if is_instance_valid(attackComponent2.target):
            if is_instance_valid(attackComponent2.target.cell):
                var surround: TowerDefenseCharacter = attackComponent2.target.cell.GetSurround()
                if is_instance_valid(surround):
                    surround.Hurt(100.0)
                    flag = true
        if !flag:
            TowerDefenseExplode.CreateExplode(global_position, Vector2(1.25, 0.25), eventList, [], camp, instance.collisionFlags)
        var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(QUAKE, gridPos, "Idle")
        effect.global_position = transformPoint.global_position - Vector2(0, 30)
        characterNode.add_child(effect)
        quake = false
    if pogoPlant:
        isJump = true
        if jumpWait > 0:
            jumpWait -= 1



        else:
            jumpWait = randi_range(2, 3)
            var tween = create_tween()
            tween.set_ease(Tween.EASE_IN_OUT)
            tween.set_trans(Tween.TRANS_SINE)
            tween.tween_property(self, ^"global_position:x", jumpToPos, 0.5)
            ySpeed = -400
            quake = true
            await tween.finished
            pogoPlant = false
        await get_tree().create_timer(0.2, false).timeout
        isJump = false

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "pogo":
            pass
        "jump_check":
            pass

func CanBlock() -> bool:
    if is_instance_valid(moveTween):
        return hasPogo && !moveTween.is_running()
    return hasPogo

func BlockType() -> String:
    return "Jump"

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    pogoPlant = false
    ySpeed = -500
    target.Hurt(100.0)
    moveTween = create_tween()
    moveTween.set_ease(Tween.EASE_OUT)
    moveTween.set_trans(Tween.TRANS_CUBIC)
    moveTween.tween_property(self, ^"global_position:x", global_position.x + TowerDefenseManager.GetMapGridSize().x * 1.5, 2.0)
    AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
