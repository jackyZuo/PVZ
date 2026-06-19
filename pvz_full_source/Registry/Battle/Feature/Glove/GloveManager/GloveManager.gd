class_name GloveManager extends Control

@onready var gloveButton: TextureButton = %GloveButton
@onready var gloveSprite: Sprite2D = %GloveSprite

var gloveShow: bool = false
var glovePressedAwait: bool = false

var mapControl: TowerDefenseMapControl
var mapFeature: TowerDefenseBattleFeatureMap
var mapGloveSprite: Sprite2D
var previewSprite: AdobeAnimateSprite = null

func _ready() -> void :
    if is_instance_valid(gloveButton):
        gloveButton.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    mapGloveSprite = Sprite2D.new()
    mapGloveSprite.visible = false
    if is_instance_valid(mapControl) && is_instance_valid(mapControl.spriteNode):
        mapControl.spriteNode.add_child(mapGloveSprite)
    if is_instance_valid(gloveSprite) && is_instance_valid(gloveSprite.texture):
        mapGloveSprite.texture = gloveSprite.texture
    await get_tree().physics_frame

func _exit_tree() -> void :
    if is_instance_valid(mapGloveSprite):
        mapGloveSprite.queue_free()
    FreePreviewSprite()

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if !is_instance_valid(gloveButton):
        return
    if !glovePressedAwait && Input.is_action_just_pressed("Glove"):
        if !TowerDefenseManager.IsIZMMode() && !TowerDefenseManager.IsIZM2Mode():
            gloveButton.button_pressed = !gloveButton.button_pressed
            var gloveFeature: TowerDefenseBattleFeatureGlove = TowerDefenseManager.GetGloveFeature()
            if is_instance_valid(gloveFeature):
                gloveFeature.GloveButtonPressed()

func Init(_mapControl: TowerDefenseMapControl, _mapFeature: TowerDefenseBattleFeatureMap) -> void :
    mapControl = _mapControl
    mapFeature = _mapFeature
    if is_instance_valid(mapControl) && is_instance_valid(mapControl.spriteNode) && is_instance_valid(mapGloveSprite):
        if mapGloveSprite.get_parent() == null:
            mapControl.spriteNode.add_child(mapGloveSprite)

func GloveButtonPressed() -> void :
    var gloveFeature: TowerDefenseBattleFeatureGlove = TowerDefenseManager.GetGloveFeature()
    if is_instance_valid(gloveFeature):
        gloveFeature.GloveButtonPressed()

func UpdateDisplay() -> void :
    if is_instance_valid(gloveButton) && is_instance_valid(gloveSprite):
        gloveSprite.visible = !gloveButton.button_pressed
        if gloveSprite.visible && is_instance_valid(gloveSprite.texture):
            gloveSprite.scale = Vector2.ONE * 80.0 / gloveSprite.texture.get_width()

func UpdateGloveSprite(_mapControl: TowerDefenseMapControl) -> void :
    if mapGloveSprite:
        mapGloveSprite.visible = true
        if mapGloveSprite.texture:
            mapGloveSprite.scale = Vector2.ONE * 80.0 / mapGloveSprite.texture.get_width()
        if is_instance_valid(_mapControl) && is_instance_valid(_mapControl.spriteNode):
            mapGloveSprite.position = _mapControl.spriteNode.get_local_mouse_position() - Vector2(-35.0, 35.0)

func ShowMapGloveSprite(_show: bool) -> void :
    if is_instance_valid(mapGloveSprite):
        mapGloveSprite.visible = _show

func SetMapGloveSpritePos(pos: Vector2) -> void :
    if is_instance_valid(mapGloveSprite):
        mapGloveSprite.position = pos

func SetGloveButtonPressed(pressed: bool) -> void :
    if is_instance_valid(gloveButton):
        gloveButton.button_pressed = pressed

func IsGloveButtonPressed() -> bool:
    if is_instance_valid(gloveButton):
        return gloveButton.button_pressed
    return false

func CreatePreviewSprite(character: TowerDefenseCharacter) -> void :
    FreePreviewSprite()
    if !is_instance_valid(character):
        return
    var characterConfig: TowerDefenseCharacterConfig = character.config
    previewSprite = TowerDefenseManager.GetCharacterSprite(characterConfig.name)
    previewSprite.light_mask = 0
    previewSprite.modulate.a = 0.5
    previewSprite.z_index = 1000
    previewSprite.position = Vector2(-100, -100)
    previewSprite.meshColor.a = 0.5
    if is_instance_valid(mapControl) && is_instance_valid(mapControl.spriteNode):
        mapControl.spriteNode.add_child(previewSprite)

func FreePreviewSprite() -> void :
    if is_instance_valid(previewSprite):
        previewSprite.queue_free()
    previewSprite = null
