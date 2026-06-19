extends Control

const LEVEL_EDITOR_QUIZ_LEVEL_ITEM = preload("uid://3rogaxqqkxn2")

@onready var quizDragMenu: DragMenu = %QuizDragMenu
@onready var mapChooseButton: MainButton = %MapChooseButton
@onready var quizMapChooseRect: ReferenceRect = %QuizMapChooseRect

var mapChooseReady: bool = false
var mapChooseOver: bool = false
var currentChoose: float = 0

func _ready() -> void :
    for mapName: String in ResourceManager.MAPS.keys():
        var item = LEVEL_EDITOR_QUIZ_LEVEL_ITEM.instantiate()
        quizDragMenu.add_child(item)
        item.Init(mapName)

func _physics_process(delta: float) -> void :
    if !mapChooseReady:
        return
    currentChoose = fmod(currentChoose + delta * randf() * 50.0, quizDragMenu.get_child_count())
    quizDragMenu.currentIndex = floor(currentChoose)

func Enter() -> void :
    var config: TowerDefenseLevelConfig = load("uid://ccdkb1f5papjm").duplicate(true)
    config.Init()
    config.map = quizDragMenu.get_child(quizDragMenu.currentIndex).map
    config.featureData["Map"]["MapName"] = config.map
    TowerDefenseManager.currentLevelConfig = config
    SceneManager.ChangeScene("TowerDefense")

func MapChooseButtonPressed() -> void :
    mapChooseButton.visible = false
    quizMapChooseRect.visible = true
    mapChooseOver = true
    mapChooseReady = true
    await get_tree().create_timer(randf_range(3.0, 5.0), false).timeout
    mapChooseReady = false
    await get_tree().create_timer(1.0, false).timeout
    Enter()
