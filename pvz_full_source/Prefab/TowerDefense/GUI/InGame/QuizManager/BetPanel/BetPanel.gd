extends Control

@onready var betCoinSpinBox: SpinBox = %BetCoinSpinBox
@onready var checkBoxNode: Control = %CheckBoxNode
@onready var winCheckBox: CheckBox = %WinCheckBox
@onready var failCheckBox: CheckBox = %FailCheckBox
@onready var skipCheckBox: CheckBox = %SkipCheckBox
@onready var betCoinLabel: Label = %BetCoinLabel
@onready var lineLabel: Label = %LineLabel
@onready var chooseLabel: Label = %ChooseLabel

var line: int = 1

func Init(_line: int = 1) -> void :
    line = _line
    lineLabel.text = "%d行 ：" % line

func Finish() -> void :
    betCoinSpinBox.visible = false
    checkBoxNode.visible = false
    betCoinLabel.visible = true
    betCoinLabel.text = "%d 金币" % int(betCoinSpinBox.value)
    chooseLabel.visible = true
    if winCheckBox.button_pressed:
        chooseLabel.text = "赢"
    if failCheckBox.button_pressed:
        chooseLabel.text = "输"
    if skipCheckBox.button_pressed:
        chooseLabel.text = "跳"

func WinCheckBoxToggled(toggledOn: bool) -> void :
    if !winCheckBox.button_pressed:
        winCheckBox.set_pressed_no_signal(true)
        toggledOn = true
    if toggledOn:
        failCheckBox.set_pressed_no_signal(false)
        skipCheckBox.set_pressed_no_signal(false)

func FailCheckBoxToggled(toggledOn: bool) -> void :
    if !failCheckBox.button_pressed:
        failCheckBox.set_pressed_no_signal(true)
        toggledOn = true
    if toggledOn:
        winCheckBox.set_pressed_no_signal(false)
        skipCheckBox.set_pressed_no_signal(false)

func SkipCheckBoxToggled(toggledOn: bool) -> void :
    if !skipCheckBox.button_pressed:
        skipCheckBox.set_pressed_no_signal(true)
        toggledOn = true
    if toggledOn:
        failCheckBox.set_pressed_no_signal(false)
        winCheckBox.set_pressed_no_signal(false)
