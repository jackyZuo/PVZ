class_name TowerDefenseProgessManager extends Control

@onready var levelNameLabel: Label = %LevelNameLabel
@onready var difficultLabel: Label = %DifficultLabel
@onready var survivalLabel: Label = %SurvivalLabel

@onready var progressMeter: GeneralProgressMeter = %GeneralProgressMeter

var progessFeature

func SetupUI(difficult: String, levelName: String, isSurvival: bool = false, survivalRoundNum: int = 0) -> void :
    var difiicultString: String = ""
    match difficult:
        "Normal":
            difiicultString = "正常"
            difficultLabel.modulate.g = 255.0 / 2.0
        "Difficult":
            difiicultString = "困难"
            difficultLabel.modulate.g = 0.0
        "Ultimate":
            difiicultString = "极限"
            difficultLabel.modulate.g = 0.0
    levelNameLabel.text = levelName
    difficultLabel.text = tr("INGAME_DIFFICULT") % [difiicultString]
    if isSurvival:
        survivalLabel.text = tr("PLAYERS_SURVIVAL_LEVEL_DESCRIBE") % [survivalRoundNum]
