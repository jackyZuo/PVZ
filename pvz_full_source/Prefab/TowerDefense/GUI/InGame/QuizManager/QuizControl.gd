class_name QuizControl extends Control

signal run_button_pressed

@onready var startGUINode: Control = %StartGUINode
@onready var changePresentBoxButtonNode: Control = %ChangePresentBoxButtonNode
@onready var betPanelBack: Panel = %BetPanelBack
@onready var betPanelNode: Control = %BetPanelNode
@onready var coinLabel: Label = %CoinLabel

func _exit_tree() -> void :
    TowerDefenseManager.coinBank.Hide()
    BroadCastManager.BraodCastClear()

func RunButtonPressed() -> void :
    run_button_pressed.emit()
