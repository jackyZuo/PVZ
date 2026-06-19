class_name TowerDefenseControl extends Node

@export var buttonPause: MainButton
@export var checkBox2X: CheckBox
@export var optionButton: SpriteBrightButton

var levelConfig: TowerDefenseLevelBaseConfig
var hasProgress: bool = false

func Init(_levelConfig: TowerDefenseLevelBaseConfig) -> void :
    levelConfig = _levelConfig
    levelConfig.Init()
    TowerDefenseManager.currentLevelConfig = levelConfig
    TowerDefenseManager.currentControl = self

func _ready() -> void :
    buttonPause.visible = false
    buttonPause.toggled.connect(ButtonPauseToggled)
    checkBox2X.visible = false
    checkBox2X.toggled.connect(CheckBox2XToggled)
    optionButton.visible = false
    optionButton.pressed.connect(OptionButtonPressed)


@warning_ignore("unused_parameter")
func ButtonPauseToggled(toggled: bool) -> void :
    if toggled:
        AudioManager.AudioPlay("Pause", AudioManagerEnum.TYPE.SFX, 0.0, true, true)
        DialogManager.DialogCreate("BattlePause").close.connect(
            func():
                if is_instance_valid(buttonPause):
                    buttonPause.button_pressed = false
                if Global.isMultiplayerMode and MultiPlayerManager.IsConnect():
                    MultiPlayerManager.SendResume()
        )

func CheckBox2XToggled(toggled: bool) -> void :
    if toggled:

        AudioManager.AudioPlay("2XSpeedOn", AudioManagerEnum.TYPE.SFX)
        if levelConfig.finishMethod != TowerDefenseEnum.LEVEL_FINISH_METHOD.QUIZ:
            Global.timeScale = levelConfig.baseTimeScale * 1.5
        else:
            Global.timeScale = levelConfig.baseTimeScale * 3.0
    else:

        AudioManager.AudioPlay("2XSpeedDown", AudioManagerEnum.TYPE.SFX)
        Global.timeScale = levelConfig.baseTimeScale

func OptionButtonPressed() -> void :
    DialogManager.DialogCreate("BattleOption")
