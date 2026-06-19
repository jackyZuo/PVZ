@tool
extends TowerDefenseZombie

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

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
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    scale.x = - sign(scale.x) * scale.x

func Spawn() -> void :
    global_position.x = TowerDefenseManager.GetMapCellPlantPos(Vector2(5, 0)).x
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)

func PreSpawn() -> void :
    scale.x = - sign(scale.x) * scale.x

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
    await get_tree().physics_frame
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

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "pogo":
            if ySpeed == 0:
                Land()
        "jump_check":
            pass

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

func DestroySet() -> void :
    super.DestroySet()
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if global_position.x > groundRight + 150:
        var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
        effect.global_position = global_position
        characterNode.add_child(effect)
        var packetBank: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData("ChessZombie")
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetBank.GetZombieList().pick_random())
        var character = packetConfig.Create(global_position, gridPos)
        characterNode.add_child(character)
        var _hitpointScale: float = instance.hitpointScale
        var _scale: Vector2 = transformPoint.scale
        ( func():
            if is_instance_valid(character):
                if is_instance_valid(character.instance):
                    character.instance.hitpointScale = _hitpointScale
                if is_instance_valid(character.transformPoint):
                    character.transformPoint.scale = _scale).call_deferred()
        if instance.hypnoses:
            character.Hypnoses()
        character.Walk.call_deferred()

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
