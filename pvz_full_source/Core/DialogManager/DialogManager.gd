extends Node2D

@onready var dialogLayer: CanvasLayer = %DialogLayer

const DIALOGS: Dictionary = {
    "NewVersion": preload("uid://byl6sdrqwtna6"), 

    "BattlePause": preload("uid://dfo6k1agbut6f"), 
    "MainMenuOption": preload("uid://b0npiop54wclo"), 

    "Login": preload("uid://de36jvnn3ximt"), 
    "Regist": preload("uid://dhh2llblcos5k"), 

    "ReStart": preload("uid://cv6y0meevfp1m"), 

    "BattleOption": preload("uid://dtstbivduflfa"), 
    "BattleFail": preload("uid://vjoytf5ho72h"), 
    "Pause": preload("uid://bqcytklobbjc5"), 
    "DeleteUser": preload("uid://b7ugvdt5744hb"), 
    "ExitGame": preload("uid://2ruypbgb1o60"), 
    "NewUser": preload("uid://fluy240kgqxt"), 
    "RenameUser": preload("uid://cinxg1baricor"), 
    "User": preload("uid://bl4axhkknocdw"), 

    "DifficultWarning": preload("uid://b3ihu8d0tlfdj"), 

    "ShopSale": preload("uid://7uohxkgjtfq1"), 
    "ShopCantSale": preload("uid://dh52k7mi2sqxe"), 

    "Help": preload("uid://bb57xq2pya6qc"), 
    "Almanac": preload("uid://54lyi8ygt8gb"), 
    "Shop": preload("uid://dj1q7rgc2viko"), 
    "TryLevel": preload("uid://bqgqsw4x8hpsc"), 
    "StarExchange": preload("uid://wipun8o16gvw"), 

    "DailyChallenge": preload("uid://rpjdq2sskhcc"), 
    "DailyChallengeLevelChoose": preload("uid://kh5l2bpv5cij"), 
    "DailyChallengeLevelAward": preload("uid://vsl60p6vfwq8"), 

    "LevelEditorTips": preload("uid://bq3p568k734sc"), 
    "LevelEditorNewLevel": preload("uid://dla7fmvvo2eyt"), 
    "MyLevelDelete": preload("uid://dlbvaubvob4fa"), 

    "DiyLevelChange": preload("uid://dpqscpnd01xpe"), 
    "OnlineLevelExchange": preload("uid://dne6cdlf3sqv0"), 

    "OnlineLevelPreview": preload("uid://7s2pv78sxbll"), 

    "DialogBoxTips": preload("uid://b5okjyouryjct"), 
    "DialogBoxChoose": preload("uid://cux0wbsftgq37"), 
    "DialogBoxInput": preload("uid://bm70be8qeyqip"), 
    "MultiplayerLobby": preload("res://Prefab/GUI/DialogBox/DialogBoxGeneral/DialogBoxMultiplayerLobby/DialogBoxMultiplayerLobby.tscn")
}

func _ready() -> void :
    SceneManager.sceneChange.connect(Clear)

func DialogCreate(dialogName: String, data: Dictionary = {}) -> DialogBoxBase:
    var dialog: DialogBoxBase = DIALOGS[dialogName].instantiate()
    dialog.Init(data)
    dialogLayer.add_child(dialog)
    dialog.global_position = Vector2.ZERO
    return dialog

@warning_ignore("unused_parameter")
func Clear(sceneName: String) -> void :
    for dialog in dialogLayer.get_children():
        dialog.queue_free()
    get_tree().paused = false
