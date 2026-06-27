@tool
class_name GeneralProgressMeter extends Control

const GENERAL_PROGRESS_FLAG: PackedScene = preload("res://Prefab/GUI/ProgressMeter/ProgressFlag/GeneralProgressFlag.tscn")

@onready var progressBar: TextureProgressBar = %ProgressBar
@onready var headTexture: TextureRect = %HeadTexture
@onready var flagContainer: HBoxContainer = %FlagContainer

@export var hideItem: bool = false

@export var waveNum: int = 1:
    set(_waveNum):
        waveNum = _waveNum
        if Engine.is_editor_hint():
            FlagRefresh()

@export var waveInterval: int = 1:
    set(_waveInterval):
        waveInterval = _waveInterval
        if Engine.is_editor_hint():
            FlagRefresh()

@export var previewWave: int = 0:
    set(_previewWave):
        previewWave = _previewWave
        previewWave = clamp(previewWave, 0, waveNum)
        if hideItem || flagList.is_empty():
            return
        @warning_ignore("integer_division")
        var flagIndex: int = previewWave / waveInterval
        if flagIndex > flagList.size():
            flagIndex = flagList.size()
        for flagId in range(flagList.size()):
            flagList[flagId].reach = flagId < flagIndex

var flagList: Array[GeneralProgressFlag] = []

func Init(_waveNum: int, _waveInterval: int):
    await get_tree().create_timer(0.1, false).timeout
    waveNum = _waveNum
    waveInterval = _waveInterval
    FlagRefresh()
    if hideItem:
        headTexture.visible = false

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    if hideItem:
        headTexture.visible = false
    if progressBar.max_value > 0.0:
        headTexture.position.x = 140.0 - 150.0 * progressBar.value / progressBar.max_value
    match TowerDefenseInGameLevelControl.instance.config.finishMethod:
        TowerDefenseEnum.LEVEL_FINISH_METHOD.WAVE, TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM2:
            progressBar.value = lerpf(progressBar.value, progressBar.max_value * float(previewWave) / float(waveNum), 0.1 * delta)
        TowerDefenseEnum.LEVEL_FINISH_METHOD.IZM:
            progressBar.value = lerpf(progressBar.value, progressBar.max_value * float(previewWave) / float(waveNum), 2.0 * delta)

func SetWaveCurrent(waveCurrent: int) -> void :
    previewWave = waveCurrent

func FlagRefresh() -> void :
    if hideItem:
        return
    if !flagContainer:
        return
    for flag in flagContainer.get_children():
        if flag:
            flag.queue_free()
    flagList.clear()
    @warning_ignore("integer_division")
    var flagNum: int = floor(waveNum / waveInterval)

    flagContainer.add_theme_constant_override("separation", floor(150.0 / flagNum))
    for flagId in range(flagNum):
        var flag: GeneralProgressFlag = GENERAL_PROGRESS_FLAG.instantiate() as GeneralProgressFlag
        flagContainer.add_child(flag)
        flagList.insert(0, flag)

    @warning_ignore("integer_division")
    var flagIndex: int = previewWave / waveInterval
    if flagIndex > flagList.size():
        flagIndex = flagList.size()
    for flagId in range(flagList.size()):
        flagList[flagId].reach = flagId < flagIndex
