extends Control

@onready var openButton: MainButton = %OpenButton
@onready var guiLayer: CanvasLayer = $GUILayer

@onready var openAllLevelCheckBox: CheckBox = %OpenAllLevelCheckBox
@onready var coinMaxCheckBox: CheckBox = %CoinMaxCheckBox
@onready var sunMaxCheckBox: CheckBox = %SunMaxCheckBox
@onready var packetSelectCheckBox: CheckBox = %PacketSelectCheckBox
@onready var packetOpenAllCheckBox: CheckBox = %PacketOpenAllCheckBox
@onready var packetColdDownCheckBox: CheckBox = %PacketColdDownCheckBox
@onready var openAllCustomCheckBox: CheckBox = %OpenAllCustomCheckBox
@onready var openGloveCheckBox: CheckBox = %OpenGloveCheckBox
@onready var unlimitedFireCheckBox: CheckBox = %UnlimitedFireCheckBox
@onready var plantInvincibleCheckBox: CheckBox = %PlantInvincibleCheckBox
@onready var noLoseCheckBox: CheckBox = %NoLoseCheckBox
@onready var sunSpinBox: SpinBox = %SunSpinBox
@onready var coinSpinBox: SpinBox = %CoinSpinBox
@onready var crystalSpinBox: SpinBox = %CrystalSpinBox
@onready var wavePausedCheckBox: CheckBox = %WavePausedCheckBox
@onready var noZombieSpawnCheckBox: CheckBox = %NoZombieSpawnCheckBox
@onready var waveSpinBox: SpinBox = %WaveSpinBox
@onready var brainInvincibleCheckBox: CheckBox = %BrainInvincibleCheckBox
@onready var gameSpeedLabel: Label = %GameSpeedLabel
@onready var gameSpeedSlider: HSlider = %GameSpeedSlider
@onready var fpsLabel: Label = %FpsLabel
@onready var waveInfoLabel: Label = %WaveInfoLabel
@onready var characterCountLabel: Label = %CharacterCountLabel

@export var debug: bool = false

@export var debugUnlimitedFire: bool = false
@export var debugCoinMax: bool = false
@export var debugOpenAllLevel: bool = false
@export var debugSunMax: bool = false
@export var debugPacketSelect: bool = false
@export var debugPacketOpenAll: bool = false
@export var debugPacketColdDown: bool = false
@export var debugOpenAllCustom: bool = false
@export var debugOpenGlove: bool = false

@export var debugPlantInvincible: bool = false
@export var debugNoLose: bool = false
@export var debugWavePaused: bool = false
@export var debugNoZombieSpawn: bool = false
@export var debugBrainInvincible: bool = false

func _ready() -> void :
    if !debug:
        openButton.visible = false
        process_mode = ProcessMode.PROCESS_MODE_DISABLED
        return
    Init()

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if debug && Input.is_action_just_pressed("Command"):
        grab_focus()
        guiLayer.visible = !guiLayer.visible
        get_tree().paused = guiLayer.visible

func _process(_delta: float) -> void :
    if !debug:
        return
    fpsLabel.text = "FPS: %d" % Engine.get_frames_per_second()
    if is_instance_valid(TowerDefenseBattleFeatureWave.instance):
        var wave = TowerDefenseBattleFeatureWave.instance
        var totalWaves = wave.config.wave.size() if wave.config else 0
        waveInfoLabel.text = "波次: %d/%d\n血量: %.0f/%.0f" % [wave.currentWave, totalWaves, wave.currentHpPoint, wave.currentHpPointTotal]
        if waveSpinBox.max_value != totalWaves:
            waveSpinBox.max_value = max(1, totalWaves)
    var registry = TowerDefenseManager.characterRegistry
    if is_instance_valid(registry):
        var plantCount: int = get_tree().get_node_count_in_group("Plant")
        var zombieCount: int = get_tree().get_node_count_in_group("Zombie")
        characterCountLabel.text = "植物: %d  僵尸: %d  总数: %d" % [plantCount, zombieCount, plantCount + zombieCount]

func Init() -> void :
    openAllLevelCheckBox.button_pressed = debugOpenAllLevel
    openAllLevelCheckBox.toggled.connect( func(toggle: bool): debugOpenAllLevel = toggle)
    coinMaxCheckBox.button_pressed = debugCoinMax
    coinMaxCheckBox.toggled.connect( func(toggle: bool): debugCoinMax = toggle)
    sunMaxCheckBox.button_pressed = debugSunMax
    sunMaxCheckBox.toggled.connect( func(toggle: bool): debugSunMax = toggle)
    packetSelectCheckBox.button_pressed = debugPacketSelect
    packetSelectCheckBox.toggled.connect( func(toggle: bool): debugPacketSelect = toggle)
    packetOpenAllCheckBox.button_pressed = debugPacketOpenAll
    packetOpenAllCheckBox.toggled.connect( func(toggle: bool): debugPacketOpenAll = toggle)
    packetColdDownCheckBox.button_pressed = debugPacketColdDown
    packetColdDownCheckBox.toggled.connect( func(toggle: bool): debugPacketColdDown = toggle)
    openAllCustomCheckBox.button_pressed = debugOpenAllCustom
    openAllCustomCheckBox.toggled.connect( func(toggle: bool): debugOpenAllCustom = toggle)
    openGloveCheckBox.button_pressed = GameSaveManager.GetFeatureValue("Glove") > 0
    openGloveCheckBox.toggled.connect( func(toggle: bool): CommandManager.debugOpenGlove = toggle)
    unlimitedFireCheckBox.button_pressed = debugUnlimitedFire
    unlimitedFireCheckBox.toggled.connect( func(toggle: bool): debugUnlimitedFire = toggle)
    plantInvincibleCheckBox.button_pressed = debugPlantInvincible
    plantInvincibleCheckBox.toggled.connect( func(toggle: bool): debugPlantInvincible = toggle)
    noLoseCheckBox.button_pressed = debugNoLose
    noLoseCheckBox.toggled.connect( func(toggle: bool): debugNoLose = toggle)
    wavePausedCheckBox.button_pressed = debugWavePaused
    wavePausedCheckBox.toggled.connect( func(toggle: bool): debugWavePaused = toggle)
    noZombieSpawnCheckBox.button_pressed = debugNoZombieSpawn
    noZombieSpawnCheckBox.toggled.connect( func(toggle: bool): debugNoZombieSpawn = toggle)
    brainInvincibleCheckBox.button_pressed = debugBrainInvincible
    brainInvincibleCheckBox.toggled.connect( func(toggle: bool): debugBrainInvincible = toggle)
    gameSpeedSlider.value_changed.connect(
        func(value: float):
            Global.timeScale = value
            gameSpeedLabel.text = "游戏速度:%.1fx" % value
    )

func OpenButtonToggled(toggledOn: bool) -> void :
    guiLayer.visible = toggledOn
    get_tree().paused = guiLayer.visible

func _on_speed_reset_button_pressed() -> void :
    gameSpeedSlider.value = 1.0

func SetSunValue() -> void :
    TowerDefenseManager.SetSun(int(sunSpinBox.value))

func SetCoinValue() -> void :
    TowerDefenseManager.coinBank.num = int(coinSpinBox.value)

func SetCrystalValue() -> void :
    GameSaveManager.SetKeyValue("CrystalNum", int(crystalSpinBox.value))
    GameSaveManager.Save()

func TestLevelButtonPressed() -> void :
    TowerDefenseManager.currentLevelConfig = load("uid://bfl6f5wb3lu7m")
    guiLayer.visible = !guiLayer.visible
    get_tree().paused = guiLayer.visible
    Global.enterLevelMode = "LevelChoose"
    SceneManager.ChangeScene("TowerDefense")

func LoadLevelButtonPressed() -> void :
    @warning_ignore("unused_parameter")
    DisplayServer.file_dialog_show("打开关卡文件", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.json,*.tres"], 
        func FileOpen(status: bool, selectedPaths: PackedStringArray, selectedFilterIndex: int) -> void :
            if selectedPaths.size() > 0:
                match selectedPaths[0].get_extension():
                    "json":
                        var file = FileAccess.open(selectedPaths[0], FileAccess.READ)
                        var content = file.get_as_text()
                        var json = JSON.new()
                        json.parse(content, true)
                        var config: TowerDefenseLevelConfig = TowerDefenseLevelConfig.new()
                        config.data = json
                        config.Init()
                        json = null
                        TowerDefenseManager.currentLevelConfig = config.duplicate_deep()
                        guiLayer.visible = false
                        get_tree().paused = guiLayer.visible
                        Global.enterLevelMode = "LoadLevel"
                        SceneManager.ChangeScene("TowerDefense")
                        Global.isEditor = false
                    "tres":
                        var res = load(selectedPaths[0])
                        if res is TowerDefenseLevelConfig:
                            TowerDefenseManager.currentLevelConfig = res.duplicate_deep()
                            guiLayer.visible = false
                            get_tree().paused = guiLayer.visible
                            Global.enterLevelMode = "LoadLevel"
                            SceneManager.ChangeScene("TowerDefense")
                            Global.isEditor = false
                        else:
                            BroadCastManager.BroadCastFloatCreate("不是关卡文件", Color.RED)
    )

func SkipToWave() -> void :
    var wave = TowerDefenseBattleFeatureWave.instance
    if !wave:
        return
    var targetWave = int(waveSpinBox.value)
    while wave.currentWave < targetWave && !wave.waveFinal:
        wave.timer = wave.nextWaveTime
        wave.awaitSpawn = false
        await get_tree().create_timer(0.2, false).timeout

func SkipToFinalWave() -> void :
    var wave = TowerDefenseBattleFeatureWave.instance
    if !wave:
        return
    if !wave.waveStart:
        wave.waveStart = true
    while !wave.waveFinal:
        wave.timer = wave.nextWaveTime
        wave.awaitSpawn = false
        await get_tree().create_timer(0.2, false).timeout

func SkipWaveWait() -> void :
    var wave = TowerDefenseBattleFeatureWave.instance
    if !wave:
        return
    wave.timer = wave.nextWaveTime
    wave.awaitSpawn = false

func KillAllZombies() -> void :
    for zombie in get_tree().get_nodes_in_group("Zombie"):
        if is_instance_valid(zombie) && zombie is TowerDefenseZombie:
            if !zombie.instance.die:
                zombie.Hurt(1000000000000)

func InstantWin() -> void :
    var wave = TowerDefenseBattleFeatureWave.instance
    if !wave:
        return
    KillAllZombies()
    wave.waveStart = true
    wave.waveFinal = true
    wave.final.emit()
    wave.awaitSpawn = false

func RestoreAllMowers() -> void :
    var currentControl = TowerDefenseManager.currentControl
    var mowerFeature: TowerDefenseBattleFeatureMower = currentControl.GetFeature("Mower")
    if !mowerFeature:
        return
    var mapFeature = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            if !is_instance_valid(mowerFeature.mowerLine[line]):
                mowerFeature.CreateMower(line)

func RemoveAllMowers() -> void :
    var currentControl = TowerDefenseManager.currentControl
    var mowerFeature: TowerDefenseBattleFeatureMower = currentControl.GetFeature("Mower")
    if !mowerFeature:
        return
    for line in range(mowerFeature.mowerLine.size()):
        if is_instance_valid(mowerFeature.mowerLine[line]):
            mowerFeature.mowerLine[line].queue_free()
            mowerFeature.mowerLine[line] = null

func ResetAllBrains() -> void :
    var currentControl = TowerDefenseManager.currentControl
    var brainFeature: TowerDefenseBattleFeatureBrain = currentControl.GetFeature("Brain")
    if !brainFeature:
        return
    var mapFeature = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(brainFeature.brainLine.size()):
        if is_instance_valid(brainFeature.brainLine[line]):
            brainFeature.brainLine[line].queue_free()
            brainFeature.brainLine[line] = null
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            brainFeature.CreateBrain(line)
