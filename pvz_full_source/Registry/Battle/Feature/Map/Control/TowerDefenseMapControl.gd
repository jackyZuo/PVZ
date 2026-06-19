class_name TowerDefenseMapControl extends Node2D

@onready var canvasModulate: CanvasModulate = %CanvasModulate
@onready var spriteNode: Node2D = %SpriteNode
@onready var mapNode: Node2D = %MapNode
@onready var mapIceCap: Node2D = %MapIceCap
@onready var changeMapLayer: CanvasLayer = %ChangeMapLayer

@export var canvasModulateCharacter: CanvasModulate

var editorSprite: Sprite2D

var mapFeature: TowerDefenseBattleFeatureMap

func _ready() -> void :
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        spriteNode.scale = Vector2.ONE * 0.85
    for node: Node in mapNode.get_children():
        node.queue_free()

func _physics_process(_delta: float) -> void :
    if is_instance_valid(mapFeature) && is_instance_valid(TowerDefenseManager.currentControl):
        if !TowerDefenseManager.currentControl.isGameRunning && !TowerDefenseManager.currentControl.isGameFail:
            mapFeature.ProcessInput()

func _exit_tree() -> void :
    pass

@warning_ignore("unused_parameter")
func UpdateCanvasModulate(delta: float) -> void :
    canvasModulate.visible = GameSaveManager.GetConfigValue("MapEffect")
    if is_instance_valid(canvasModulateCharacter):
        canvasModulateCharacter.visible = canvasModulate.visible
    if is_instance_valid(mapFeature) && mapFeature.isChange:
        canvasModulate.color = mapFeature.currentGradient.gradient.sample(mapFeature.currentGradientPos)
        if is_instance_valid(canvasModulateCharacter):
            canvasModulateCharacter.color = canvasModulate.color

func IsConfirmInput() -> bool:
    if Global.isMobile:
        return Input.is_action_just_released("Press")
    return Input.is_action_just_pressed("Press")
