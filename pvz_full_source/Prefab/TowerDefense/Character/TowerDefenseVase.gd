@tool
class_name TowerDefenseVase extends TowerDefenseItem
var waterComponent: WaterComponent
var vaseContentComponent: VaseContentComponent
var entryAnimationComponent: EntryAnimationComponent
var lightDetectionComponent: LightDetectionComponent

@onready var hammer: AdobeAnimateSpriteBase = %Hammer
@onready var packetShow: TowerDefenseInGamePacketShow = %PacketShow
@onready var mouseMask: ColorRect = %MouseMask

@export var backSprite: AdobeAnimateSprite
@export var packetCanShow: bool = true
@export var waterLineSprite: AdobeAnimateSpriteBase
@export var chunkParticles: PackedScene
@export var packetBank: String = "Total"
@export var packetName: String = "":
    set(_packetName):
        if packetName != _packetName:
            packetName = _packetName
            if packetName == "":
                packetConfig = null
            else:
                packetConfig = TowerDefenseManager.GetPacketConfig(packetName).duplicate(true)
@export var packetConfig: TowerDefensePacketConfig:
    set(_packetConfig):
        packetConfig = _packetConfig
        if is_node_ready():
            if is_instance_valid(packetConfig):
                packetShow.Init(packetConfig)
                if _ShouldAlwaysShowPacket():
                    showPacket = true
                    sprite.visible = false
                    packetShow.modulate.a = 1.0
            else:
                packetShow.Clear()
                if _ShouldAlwaysShowPacket():
                    showPacket = false
                    sprite.visible = true
                    packetShow.modulate.a = 0.0

func _ShouldAlwaysShowPacket() -> bool:
    return (Global.isEditor && SceneManager.currentScene == "LevelEditorStage")

@export var useEnterAnime: bool = true

var isMoseIn: bool = false
var pressed: bool = false
var over: bool = false

var showPacket: bool = false:
    set(_showPacket):
        showPacket = _showPacket
        if !showPacket:
            packetShow.visible = false
        else:
            packetShow.visible = true

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if is_instance_valid(componentManager):
        waterComponent = componentManager.GetComponentFromType("WaterComponent")
        vaseContentComponent = componentManager.GetComponentFromType("VaseContentComponent")
        entryAnimationComponent = componentManager.GetComponentFromType("EntryAnimationComponent")
        lightDetectionComponent = componentManager.GetComponentFromType("LightDetectionComponent")
    targetRegistrationComponent.canProjectileCheck = false
    showPacket = true
    showPacket = false
    packetShow.button.visible = false
    packetShow.showCost = false
    add_to_group("Vase", true)
    var isInWater: bool = is_instance_valid(cell) && cell.IsWater()

    if isInWater:
        groundHeight = - waterComponent.waterHeight
        inGame = false
        waterComponent.inWater = true
        inGame = true
        shadowSprite.visible = false
        if is_instance_valid(shadowComponent):
            shadowComponent.SetVisible(false)

        var viewport: Viewport = get_viewport()
        var vt: Transform2D = viewport.get_screen_transform()
        vt.origin = Vector2.ZERO
        var target_pos: float = (vt * (spriteGroup.global_position + Vector2(0, 100))).y
        backSprite.set_instance_shader_parameter("discardDownPos", target_pos)
        SetSpriteGroupShaderParameter("discardDownPos", target_pos)
        var target_pos_final: float = (vt * (spriteGroup.global_position + Vector2(0, 48))).y
        var waterTween = create_tween()
        waterTween.set_parallel(true)
        waterTween.set_ease(Tween.EASE_OUT)
        waterTween.set_trans(Tween.TRANS_CUBIC)
        waterTween.tween_method(_set_sprite_discard_down_pos, target_pos, target_pos_final, 1.0)
        waterTween.tween_method(_set_back_sprite_discard_down_pos, target_pos, target_pos_final, 1.0)
        CreateSplash()
        if is_instance_valid(waterLineSprite):
            waterLineSprite.visible = true
    if !(Global.isEditor && SceneManager.currentScene == "LevelEditorStage"):
        if useEnterAnime && !TowerDefenseManager.currentControl.hasProgress:
            entryAnimationComponent.PlayFallBounce(900.0, randf_range(0.25, 1.0), 0.25)
    if !isInWater:
        mouseMask.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if (Engine.get_physics_frames() + randFreshIndex) % 5 == 0:
        if global_position.x > groundRight - 30:
            global_position.x = groundRight - 30
        mouseMask.position = spriteGroup.position + Vector2(-30, -54)
        packetShow.position.y = spriteGroup.position.y
    showPacket = is_instance_valid(packetConfig) && (lightDetectionComponent.CheckShow() || _ShouldAlwaysShowPacket())
    if showPacket:
        packetShow.modulate.a = lerpf(packetShow.modulate.a, 1.0, delta * 2.0)
        sprite.visible = false
    else:
        packetShow.modulate.a = lerpf(packetShow.modulate.a, 0.0, delta * 5.0)
        sprite.visible = true


@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !pressed:
        if isMoseIn:
            if Input.is_action_just_pressed("Press"):
                if !is_instance_valid(TowerDefenseManager.GetPacketPickControl()) || !is_instance_valid(TowerDefenseManager.GetPacketPickControl().packetPick):
                    hammer.visible = true
                    AudioManager.AudioPlay("Swing", AudioManagerEnum.TYPE.SFX)
                    hammer.SetAnimation("OpenPot", false)
                    pressed = true

func DestroySet() -> void :
    vaseContentComponent.DestroySet()

func SmashDestroy() -> void :
    if isDestroy:
        return
    isDestroy = true
    @warning_ignore("redundant_await")
    await DestroySet()
    TowerDefenseManager.CharacterUnregister(self)
    remove_from_group("Character")
    queue_free()

func MultiplayerBreak() -> void :
    if over:
        return
    over = true
    isDestroy = true
    if is_instance_valid(TowerDefenseInGameLevelControl.instance):
        TowerDefenseInGameLevelControl.instance.hasSpawn = true
    AudioManager.AudioPlay("VaseBreaking", AudioManagerEnum.TYPE.SFX)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(chunkParticles, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30.0)
    TowerDefenseGroundItemBase.characterNode.add_child(effect)
    TowerDefenseManager.CharacterUnregister(self)
    remove_from_group("Character")
    queue_free()

func MouseEntered() -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    SetSpriteGroupShaderParameter("brightStrength", 0.3)
    isMoseIn = true

func MouseExited() -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    SetSpriteGroupShaderParameter("brightStrength", 0.0)
    isMoseIn = false

func HammerAnimeCompleted(clip: String) -> void :
    match clip:
        "OpenPot":
            hammer.visible = false
            if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
                MultiPlayerManager.SendVaseBreakRequest(gridPos.x, gridPos.y)
            else:
                Destroy()

func Export() -> TowerDefenseLevelVaseConfig:
    var vaseConfig: TowerDefenseLevelVaseConfig = TowerDefenseLevelVaseConfig.new()
    vaseConfig.gridPos = gridPos
    if is_instance_valid(packetConfig):
        vaseConfig.packetName = packetConfig.saveKey
    match config.name:
        "VaseNormal":
            vaseConfig.type = "Normal"
        "VasePlant":
            vaseConfig.type = "Plant"
        "VaseZombie":
            vaseConfig.type = "Zombie"
    return vaseConfig

@warning_ignore("unused_parameter")
func BlowBack(num: float, time: float = 1.0) -> void :
    pass

func _set_sprite_discard_down_pos(value: float) -> void :
    if is_instance_valid(sprite):
        sprite.set_instance_shader_parameter("discardDownPos", value)

func _set_back_sprite_discard_down_pos(value: float) -> void :
    if is_instance_valid(backSprite):
        backSprite.set_instance_shader_parameter("discardDownPos", value)
