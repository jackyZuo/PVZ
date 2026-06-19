@tool
extends TowerDefensePlant

const DAY_VASE_CHUNKS = preload("uid://ctsxe8qhievw0")

@onready var hammer: AdobeAnimateSpriteBase = %Hammer
@onready var mouseMask: ColorRect = %MouseMask

var isMoseIn: bool = false
var pressed: bool = false
var over: bool = false

var chunksEffect: PackedScene = DAY_VASE_CHUNKS

var pressAwait: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    instance.hitpointsEmpty.disconnect(Destroy)
    instance.hitpointsEmpty.connect(Change)


func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)

    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !TowerDefenseManager.IsGameRunning():
        return

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if pressAwait:
        return
    if instance.hypnoses:
        return
    if !pressed:
        if isMoseIn:
            if Input.is_action_just_pressed("Press"):
                if !TowerDefenseManager.GetMapFeature().isChange:
                    if !is_instance_valid(TowerDefenseManager.GetPacketPickControl()) || !is_instance_valid(TowerDefenseManager.GetPacketPickControl().packetPick):
                        hammer.visible = true
                        AudioManager.AudioPlay("Swing", AudioManagerEnum.TYPE.SFX)
                        hammer.SetAnimation("OpenPot", false)
                        pressed = true
                pressAwait = true
                await get_tree().create_timer(0.1, false).timeout
                pressAwait = false

func AttackEntered() -> void :
    if TowerDefenseManager.GetMapIsNight():
        sprite.SetAnimation("Day", false, 0.1)
    else:
        sprite.SetAnimation("Night", false, 0.1)
    if !over:
        TowerDefenseManager.MapDayNightSwitch(5.0, 100.0)
        over = true

@warning_ignore("unused_parameter")
func AttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func AttackExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Day", "Night":
            TowerDefenseManager.CharacterUnregister(self)
            remove_from_group("Character")
            queue_free()

func Change() -> void :
    if TowerDefenseManager.GetMapFeature().isChange:
        return
    pressed = true
    state.send_event("ToAttack")
    Break()
    Destroy(false)

func Break() -> void :
    AudioManager.AudioPlay("VaseBreaking", AudioManagerEnum.TYPE.SFX)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(chunksEffect, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30.0)
    characterNode.add_child(effect)
    await get_tree().physics_frame

func MouseEntered() -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !is_instance_valid(TowerDefenseManager.GetPacketPickControl()) || !is_instance_valid(TowerDefenseManager.GetPacketPickControl().packetPick):
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
            Change()

func ExportVariantSave() -> Dictionary:
    return {
        "isMoseIn": isMoseIn, 
        "pressed": pressed, 
        "over": over, 
        "pressAwait": pressAwait, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    isMoseIn = data.get("isMoseIn", false)
    pressed = data.get("pressed", false)
    over = data.get("over", false)
    pressAwait = data.get("pressAwait", false)
