extends DialogBoxBase

@onready var plantHealthCheckBox: CheckBox = %PlantHealthCheckBox
@onready var zombieHealthCheckBox: CheckBox = %ZombieHealthCheckBox
@onready var packetUIFrontCheckBox: CheckBox = %PacketUIFrontCheckBox
@onready var mapEffectCheckBox: CheckBox = %MapEffectCheckBox
@onready var backgrounderCheckBox: CheckBox = %BackgrounderCheckBox
@onready var phonkCheckBox: CheckBox = %PhonkCheckBox
@onready var phonkIntensityLabel: Label = %PhonkIntensityLabel
@onready var phonkIntensitySlider: HSlider = %PhonkIntensitySlider

func _ready() -> void :
    super._ready()
    plantHealthCheckBox.button_pressed = GameSaveManager.GetConfigValue("ShowPlantHealth")
    zombieHealthCheckBox.button_pressed = GameSaveManager.GetConfigValue("ShowZombieHealth")
    packetUIFrontCheckBox.button_pressed = GameSaveManager.GetConfigValue("PacketUIFront")
    mapEffectCheckBox.button_pressed = GameSaveManager.GetConfigValue("MapEffect")
    backgrounderCheckBox.button_pressed = GameSaveManager.GetConfigValue("Backgrounder")
    phonkCheckBox.button_pressed = GameSaveManager.GetConfigValue("PhonkEnabled")
    phonkIntensitySlider.value = GameSaveManager.GetConfigValue("PhonkIntensity")
    phonkIntensityLabel.text = "果冻弹性强度:%.1f" % phonkIntensitySlider.value

    PhonkComponent.phonkEnabled = phonkCheckBox.button_pressed
    PhonkComponent.phonkIntensity = phonkIntensitySlider.value

    if Global.isMultiplayerMode:
        pasue = false
        if get_tree().paused:
            get_tree().paused = false

func PlantHealthCheckBoxToggled(toggledOn: bool) -> void :
    GameSaveManager.SetConfigValue("ShowPlantHealth", toggledOn)
    BattleEventBus.showPlantHealth.emit(toggledOn)
    GameSaveManager.SaveGameConfig()

func ZombieHealthCheckBoxToggled(toggledOn: bool) -> void :
    GameSaveManager.SetConfigValue("ShowZombieHealth", toggledOn)
    BattleEventBus.showZombieHealth.emit(toggledOn)
    GameSaveManager.SaveGameConfig()

func PacketUIFrontCheckBoxToggled(toggledOn: bool) -> void :
    GameSaveManager.SetConfigValue("PacketUIFront", toggledOn)
    BattleEventBus.packetUIFront.emit(toggledOn)
    GameSaveManager.SaveGameConfig()

func MapEffectCheckBoxToggled(toggledOn: bool) -> void :
    GameSaveManager.SetConfigValue("MapEffect", toggledOn)
    GameSaveManager.SaveGameConfig()

func BackgrounderCheckBoxToggled(toggledOn: bool) -> void :
    GameSaveManager.SetConfigValue("Backgrounder", toggledOn)
    GameSaveManager.SaveGameConfig()

func PhonkCheckBoxToggled(toggledOn: bool) -> void :
    GameSaveManager.SetConfigValue("PhonkEnabled", toggledOn)
    PhonkComponent.phonkEnabled = toggledOn
    if toggledOn:
        PhonkComponent.InjectAll()
    else:
        PhonkComponent.RemoveAll()
    GameSaveManager.SaveGameConfig()

func PhonkIntensitySliderChanged(value: float) -> void :
    GameSaveManager.SetConfigValue("PhonkIntensity", value)
    PhonkComponent.phonkIntensity = value
    phonkIntensityLabel.text = "果冻弹性强度:%.1f" % value
    GameSaveManager.SaveGameConfig()

func BackButtonPressed() -> void :
    Close()
