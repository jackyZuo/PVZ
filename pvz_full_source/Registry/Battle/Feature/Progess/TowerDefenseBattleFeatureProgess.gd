class_name TowerDefenseBattleFeatureProgess extends TowerDefenseBattleFeature

const TOWER_DEFENSE_PROGESS_MANAGER = preload("uid://dlgafsqc16cbw")

var progessManager: TowerDefenseProgessManager

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    progessManager = TOWER_DEFENSE_PROGESS_MANAGER.instantiate()
    progessManager.progessFeature = self
    control.AddUI(progessManager, 3)

func GameReady() -> void :
    pass

func GameStart() -> void :
    if !is_instance_valid(progessManager): return
    var process: TowerDefenseBattleProcess = GetProcess()
    if process is TowerDefenseBattleProcessIZM:
        progessManager.progressMeter.hideItem = true
        progessManager.progressMeter.visible = true

func ProgressInit(waveNum: int, flagWaveInterval: int) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.Init(waveNum, flagWaveInterval)

func ProgressRefresh(isSurvival: bool = false, survivalRoundNum: int = 0) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.visible = false
    progessManager.progressMeter.SetWaveCurrent(0)
    progessManager.progressMeter.progressBar.value = 0
    if isSurvival:
        progessManager.survivalLabel.text = tr("PLAYERS_SURVIVAL_LEVEL_DESCRIBE") % [survivalRoundNum]

func SetupUI(difficult: String, levelName: String, isSurvival: bool = false, survivalRoundNum: int = 0) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.SetupUI(difficult, levelName, isSurvival, survivalRoundNum)

func SetDifficultModulate(difficult: String) -> void :
    if !is_instance_valid(progessManager): return
    match difficult:
        "Normal":
            progessManager.difficultLabel.modulate.g = 255.0 / 2.0
        "Difficult":
            progessManager.difficultLabel.modulate.g = 0.0
        "Ultimate":
            progessManager.difficultLabel.modulate.g = 0.0

func SetDifficultText(difficultString: String) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.difficultLabel.text = tr("INGAME_DIFFICULT") % [difficultString]

func SetLevelName(levelName: String) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.levelNameLabel.text = levelName

func SetSurvivalText(survivalRoundNum: int) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.survivalLabel.text = tr("PLAYERS_SURVIVAL_LEVEL_DESCRIBE") % [survivalRoundNum]

func SetDifficultVisible(visible: bool) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.difficultLabel.visible = visible

func SetSurvivalVisible(visible: bool) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.survivalLabel.visible = visible

func SetLevelNameVisible(visible: bool) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.levelNameLabel.visible = visible

func SetProgressMeterVisible(visible: bool) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.visible = visible

func SetProgressMeterHideItem(hide: bool) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.hideItem = hide

func SetProgressMeterWaveCurrent(waveCurrent: int) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.SetWaveCurrent(waveCurrent)

func SetProgressMeterMaxValue(maxValue: float) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.progressBar.max_value = maxValue

func SetProgressMeterWaveNum(waveNum: int) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.waveNum = waveNum

func SetProgressMeterPreviewWave(previewWave: int) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.previewWave = previewWave

func SetProgressMeterValue(value: float) -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.progressBar.value = value

func IncrementPreviewWave() -> void :
    if !is_instance_valid(progessManager): return
    progessManager.progressMeter.previewWave += 1

func SaveFeature() -> Dictionary:
    var _data: Dictionary = {}
    if is_instance_valid(progessManager) and is_instance_valid(progessManager.levelNameLabel):
        _data["level_name"] = progessManager.levelNameLabel.text
    return _data

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    if _data.has("level_name") and is_instance_valid(progessManager) and is_instance_valid(progessManager.levelNameLabel):
        progessManager.levelNameLabel.text = _data["level_name"]

func SyncSerialize() -> Dictionary:
    var _data: Dictionary = {}
    if is_instance_valid(progessManager) and is_instance_valid(progessManager.progressMeter):
        _data["progress_value"] = progessManager.progressMeter.progressBar.value if progessManager.progressMeter.get("progressBar") else 0.0
        _data["progress_max"] = progessManager.progressMeter.progressBar.max_value if progessManager.progressMeter.get("progressBar") else 0.0
        _data["wave_num"] = progessManager.progressMeter.waveNum if progessManager.progressMeter.get("waveNum") else 0
        _data["preview_wave"] = progessManager.progressMeter.previewWave if progessManager.progressMeter.get("previewWave") else 0
    return _data

func SyncDeserialize(_data: Dictionary) -> void :
    if is_instance_valid(progessManager) and is_instance_valid(progessManager.progressMeter):
        if _data.has("progress_value") and progessManager.progressMeter.get("progressBar"):
            progessManager.progressMeter.progressBar.value = _data["progress_value"]
        if _data.has("progress_max") and progessManager.progressMeter.get("progressBar"):
            progessManager.progressMeter.progressBar.max_value = _data["progress_max"]
        if _data.has("wave_num") and progessManager.progressMeter.get("waveNum") != null:
            progessManager.progressMeter.waveNum = _data["wave_num"]
        if _data.has("preview_wave") and progessManager.progressMeter.get("previewWave") != null:
            progessManager.progressMeter.previewWave = _data["preview_wave"]
