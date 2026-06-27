@tool
extends TowerDefensePlant

const JALA_VASE_BACK_5 = preload("uid://pnu58qk7jitu")
const JALA_VASE_BODY_2 = preload("uid://3jm2ghlcepiq")
const JALA_VASE_BODY_3 = preload("uid://co3xrnatu6j8a")
const JALA_VASE_BODY_4 = preload("uid://bap8un78l21il")
const JALA_VASE_BODY_5 = preload("uid://j6cc4gemmsje")
const JALA_VASE_JALA_4 = preload("uid://buvtla2up6tvu")
const JALA_VASE_JALA_5 = preload("uid://b57i3wamhxyrb")

const JALA_VASE_CHUNKS_2 = preload("uid://btoja37o43wvj")
const JALA_VASE_CHUNKS = preload("uid://tw8msyx3iwy")

@onready var hammer: AdobeAnimateSpriteBase = %Hammer
@onready var mouseMask: ColorRect = %MouseMask

var isMoseIn: bool = false
var pressed: bool = false
var over: bool = false

var jalaNameList: Array = ["PlantJalapeno", "PlantJalaNut", "PlantJalaNutBowling", "PlantJalaCherryBomb", "PlantJalaSunShroom", "PlantJalaPurify", "PlantJalaTorch", "PlantJalaJoker", "PlantJalapenopepe", "PlantGarlicJalapeno", "PlantJalaGhost"]

var chunksEffect: PackedScene = JALA_VASE_CHUNKS

var jalaList: Array[TowerDefensePacketConfig]
var timerList: Array[float] = [0.0, 0.0, 0.0, 0.0]
var timeNeed: float = 50.0

var pressAwait: bool = false

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)

    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !TowerDefenseManager.IsGameRunning():
        return

    var attackFlag: bool = false

    for i in jalaList.size():
        if timerList[i] < timeNeed:
            timerList[i] += delta
        else:
            timerList[i] = 0.0
            ExecuteJala(jalaList[i])
            attackFlag = true

    if attackFlag:
        state.send_event("ToAttack")

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if pressAwait:
        return
    if !pressed:
        if isMoseIn:
            if Input.is_action_just_pressed("Press"):
                if !is_instance_valid(TowerDefenseManager.GetPacketPickControl().packetPick) && !instance.hypnoses:
                    hammer.visible = true
                    AudioManager.AudioPlay("Swing", AudioManagerEnum.TYPE.SFX)
                    hammer.SetAnimation("OpenPot", false)
                    pressed = true
                else:
                    if jalaList.size() < 4:
                        if (TowerDefenseManager.GetPacketPickControl().packetPick.config.characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.JALAPENO) && instance.hypnoses == TowerDefenseManager.GetPacketPickControl().packetPick.config.GetHypnoses():
                            AddJala(TowerDefenseManager.GetPacketPickControl().packetPick.config)
                            TowerDefenseManager.GetPacketPickControl().packetPick.Use()
                            TowerDefenseManager.GetPacketPickControl().Release()
                pressAwait = true
                await get_tree().create_timer(0.1, false).timeout
                pressAwait = false

func AttackEntered() -> void :
    sprite.SetAnimation("Fire", false, 0.1)

@warning_ignore("unused_parameter")
func AttackProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func AttackExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Fire":
            Idle()
        "Load":
            Idle()

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    for packetConfig: TowerDefensePacketConfig in jalaList:
        packetConfig.overrideHypnoses = instance.hypnoses

func DestroySet() -> void :
    AudioManager.AudioPlay("VaseBreaking", AudioManagerEnum.TYPE.SFX)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(chunksEffect, gridPos)
    effect.global_position = transformPoint.global_position - Vector2(0, 30.0)
    characterNode.add_child(effect)
    for packetConfig: TowerDefensePacketConfig in jalaList:
        TowerDefenseManager.SpawnPacket(packetConfig, global_position + Vector2(0, - groundHeight), 15.0, false)
    await get_tree().physics_frame

func MouseEntered() -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        return
    if !is_instance_valid(TowerDefenseManager.GetPacketPickControl().packetPick):
        SetSpriteGroupShaderParameter("brightStrength", 0.3)
        isMoseIn = true
    elif jalaList.size() < 4:
        if TowerDefenseManager.GetPacketPickControl().packetPick.config.characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.JALAPENO:
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
            Destroy()

func AddJala(packetConfig: TowerDefensePacketConfig) -> void :
    if packetConfig.saveKey == "PlantPresentBox":
        packetConfig = TowerDefenseManager.GetPacketConfig(jalaNameList.pick_random())
    if instance.hypnoses:
        packetConfig.overrideHypnoses = true
    packetConfig.ColdDownDecreaseAdd(self, "JalaVase", 0.25)
    sprite.SetAnimation("Load", false, 0.1)
    jalaList.append(packetConfig)
    UpdateVaseAppearance()
    ExecuteJala(packetConfig)

func UpdateVaseAppearance() -> void :
    match jalaList.size():
        1:
            sprite.SetReplace("JalaVase_body.png", JALA_VASE_BODY_2)
        2:
            sprite.SetReplace("JalaVase_body.png", JALA_VASE_BODY_3)
        3:
            sprite.SetReplace("JalaVase_body.png", JALA_VASE_BODY_4)
            sprite.SetReplace("JalaVase_jala.png", JALA_VASE_JALA_4)
        4:
            sprite.SetReplace("JalaVase_body.png", JALA_VASE_BODY_5)
            sprite.SetReplace("JalaVase_jala.png", JALA_VASE_JALA_5)
            sprite.SetReplace("JalaVase_back.png", JALA_VASE_BACK_5)
            chunksEffect = JALA_VASE_CHUNKS_2

func ExecuteJala(packetConfig: TowerDefensePacketConfig) -> void :
    match packetConfig.saveKey:
        "PlantJalapeno", "PlantJalaNut", "PlantJalaNutBowling":
            CreateJalapenoFire(camp, gridPos, 1800 * 0.25)
        "PlantJalaTorch", "PlantJalapenopepe":
            CreateJalapenoFireColumn(camp, gridPos, 1800 * 0.25)
        "PlantJalaCherryBomb":
            if gridPos.y > 1:
                CreateJalapenoFire(camp, gridPos - Vector2i(0, 1), 1800 * 0.25)
            CreateJalapenoFire(camp, gridPos, 1800 * 0.25)
            if gridPos.y < TowerDefenseManager.GetMapGridNum().y:
                CreateJalapenoFire(camp, gridPos + Vector2i(0, 1), 1800 * 0.25)
        "PlantJalaSunShroom":
            Bright(0.0, 0.0, 0.5, 1.5, 0.5)
            JalapenoSunCreate(global_position, -15 if instance.hypnoses else 15, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
        "PlantJalaPurify":
            CreateJalapenoFire(camp, gridPos, 1800 * 0.25)
        "PlantGarlicJalapeno":
            CreateJalapenoFire(camp, gridPos, 500 * 0.25)
        "PlantJalaJoker":
            CreateJalapenoFire(camp, gridPos, 1800 * 0.25)
            CreateJalapenoFireColumn(camp, gridPos, 1800 * 0.25)
        "PlantJalaGhost":
            CreateJalapenoFireSlash(camp, gridPos, 3000 * 0.25)
        _:
            pass

func ExportVariantSave() -> Dictionary:
    var jalaSaveKeys: Array = []
    for packetConfig: TowerDefensePacketConfig in jalaList:
        jalaSaveKeys.append(packetConfig.saveKey)
    return {
        "isMoseIn": isMoseIn, 
        "pressed": pressed, 
        "over": over, 
        "timeNeed": timeNeed, 
        "pressAwait": pressAwait, 
        "jalaSaveKeys": jalaSaveKeys, 
        "timerList": timerList.duplicate(), 
    }

func ImportVariantSave(data: Dictionary) -> void :
    isMoseIn = data.get("isMoseIn", false)
    pressed = data.get("pressed", false)
    over = data.get("over", false)
    timeNeed = data.get("timeNeed", 50.0)
    pressAwait = data.get("pressAwait", false)
    jalaList.clear()
    var jalaSaveKeys: Array = data.get("jalaSaveKeys", [])
    for saveKey: String in jalaSaveKeys:
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(saveKey)
        if instance.hypnoses:
            packetConfig.overrideHypnoses = true
        packetConfig.ColdDownDecreaseAdd(self, "JalaVase", 0.25)
        jalaList.append(packetConfig)
    UpdateVaseAppearance()
    var savedTimerList: Array = data.get("timerList", [0.0, 0.0, 0.0, 0.0])
    for i in range(timerList.size()):
        if i < savedTimerList.size():
            timerList[i] = savedTimerList[i]
