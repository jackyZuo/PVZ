@tool
extends DragMenuSelectItem

const SILVER_TROPHY = preload("uid://wrip0sbul8kd")
const GOLD_TROPHY = preload("uid://bilmjv3kylwye")
const DIAMOND_TROPHY = preload("uid://bg1gnn1guh1sl")
const MORE_GAME_STAR = preload("uid://cvth13h0ui3cq")

@onready var cupSprite: Sprite2D = %CupSprite
@onready var survivalLabel: Label = %SurvivalLabel

func Init(levelKey: String) -> void :
    var levelData: Dictionary = GameSaveManager.GetLevelValue(levelKey)
    var difficult: bool = levelData.get_or_add("Difficult", false) || levelData.get_or_add("Ultimate", false)
    if Global.currentLevelChoose != "Puzzle" && Global.currentLevelChoose != "MiniGames":
        if difficult:
            cupSprite.texture = DIAMOND_TROPHY
            return

    var mower: bool = levelData.get_or_add("Mower", false)

    if Global.currentLevelChoose != "Puzzle" && Global.currentLevelChoose != "MiniGames":
        if mower:
            cupSprite.texture = GOLD_TROPHY
            return

    var finish: bool = levelData.get_or_add("Key", {}).get_or_add("Finish", 0) > 0

    if finish:
        if Global.currentLevelChoose != "Puzzle" && Global.currentLevelChoose != "MiniGames":
            cupSprite.texture = SILVER_TROPHY
        else:
            cupSprite.texture = MORE_GAME_STAR
        return

    if GameSaveManager.HasLevelProgress(levelKey):
        var progress: TowerDefenseLevelSaveConfig = GameSaveManager.GetLevelProgress(levelKey)
        var processData: Dictionary = progress.processSave.get("main", {})
        if processData.get("isSurvival", false):
            survivalLabel.visible = true
            survivalLabel.text = "%d轮完成" % [processData.get("survivalRoundNum", 0)]
