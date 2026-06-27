@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2

var isJump: bool = false

var hasPogo: bool = true:
    set(_hasPogo):
        hasPogo = _hasPogo
        if !hasPogo:
            idleAnimeClip = "Idle"

var pogoPlant: bool = false
var jumpToPos: float
var jumpWait: int = 1

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
    if !pogoPlant:
        if !sprite.pause:
            if global_position.x > groundRight:
                global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * 2.0 * (-1 if sprite.playBack else 1)
            else:
                global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
        if !sprite.pause && attackComponent.CanAttack() && !TowerDefenseManager.backZombie:
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

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Pogo":
            if instance.ArmorHas("SpecialHelmet"):
                instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL
            else:
                instance.unUseBuffFlags = 0
            isJump = false
            hasPogo = false
            if is_instance_valid(groundHeightComponent):
                groundHeightComponent.handleWaterHeight = true
            if inWater:
                groundHeight = - waterHeight
            Walk()

func InWater() -> void :
    super.InWater()
    if hasPogo:
        groundHeight = 0.0
        if is_instance_valid(groundHeightComponent):
            groundHeightComponent.handleWaterHeight = false

func OutWater() -> void :
    if hasPogo && is_instance_valid(groundHeightComponent):
        groundHeightComponent.handleWaterHeight = true
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
    if pogoPlant && !TowerDefenseManager.backZombie:
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

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "pogo":
            pass
        "jump_check":
            pass

func CanBlock() -> bool:
    return hasPogo

func BlockType() -> String:
    return "Jump"

func ExportVariantSave() -> Dictionary:
    return {
        "isJump": isJump, 
        "hasPogo": hasPogo, 
        "pogoPlant": pogoPlant, 
        "jumpToPos": jumpToPos, 
        "jumpWait": jumpWait, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    isJump = data.get("isJump", false)
    hasPogo = data.get("hasPogo", true)
    pogoPlant = data.get("pogoPlant", false)
    jumpToPos = data.get("jumpToPos", 0.0)
    jumpWait = data.get("jumpWait", 1)

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    instance.ArmorDelete("Pogo")
    hasPogo = false
    isJump = false
    if is_instance_valid(groundHeightComponent):
        groundHeightComponent.handleWaterHeight = true
    if inWater:
        groundHeight = - waterHeight
    AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
    Walk()
