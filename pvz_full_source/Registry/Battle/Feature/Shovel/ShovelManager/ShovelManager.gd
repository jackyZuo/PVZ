class_name ShovelManager extends Control

@onready var shovelButton: TextureButton = %ShovelButton
@onready var shovelSprite: Sprite2D = %ShovelSprite

var shovelConfig: ShovelConfig
var shovelShow: bool = false
var shovelPressedAwait: bool = false

var mapControl: TowerDefenseMapControl
var mapFeature: TowerDefenseBattleFeatureMap
var shovelPick: bool = false
var mapShovelSprite: Sprite2D
var lastShovelPlant: TowerDefenseCharacter = null

func _ready() -> void :
    if is_instance_valid(shovelButton):
        shovelButton.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    var shovelName: String = GameSaveManager.GetKeyValue("CurrentShovel")
    if !shovelName:
        shovelName = "ShovelDefault"
    shovelConfig = TowerDefenseManager.GetShovel(shovelName)
    if is_instance_valid(shovelSprite):
        shovelSprite.texture = shovelConfig.texture
    mapShovelSprite = Sprite2D.new()
    mapShovelSprite.visible = false
    if is_instance_valid(mapControl) && is_instance_valid(mapControl.spriteNode):
        mapControl.spriteNode.add_child(mapShovelSprite)
    if is_instance_valid(shovelConfig):
        mapShovelSprite.texture = shovelConfig.texture
    await get_tree().physics_frame
    if is_instance_valid(shovelButton) && (TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode()):
        shovelButton.visible = false

func _exit_tree() -> void :
    if is_instance_valid(mapShovelSprite):
        mapShovelSprite.queue_free()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if is_instance_valid(shovelButton) && is_instance_valid(shovelSprite):
        shovelSprite.visible = !shovelButton.button_pressed
        if shovelSprite.visible:
            shovelSprite.scale = Vector2.ONE * 80.0 / shovelSprite.texture.get_width()

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    if !is_instance_valid(shovelButton):
        return
    if !shovelPressedAwait && Input.is_action_just_pressed("Shovel"):
        if !TowerDefenseManager.IsIZMMode() && !TowerDefenseManager.IsIZM2Mode():
            shovelButton.button_pressed = !shovelButton.button_pressed
            ShovelButtonPressed()

func ShovelButtonPressed() -> void :
    if !shovelShow && !TowerDefenseManager.currentControl.isGameRunning:
        if is_instance_valid(shovelButton):
            shovelButton.button_pressed = false
        return
    if shovelPressedAwait:
        return
    PickShovel(shovelButton.button_pressed)
    shovelPressedAwait = true
    await get_tree().create_timer(0.1, false).timeout
    shovelPressedAwait = false

func Init(_mapControl: TowerDefenseMapControl, _mapFeature: TowerDefenseBattleFeatureMap) -> void :
    mapControl = _mapControl
    mapFeature = _mapFeature
    if is_instance_valid(mapControl) && is_instance_valid(mapControl.spriteNode) && is_instance_valid(mapShovelSprite):
        if mapShovelSprite.get_parent() == null:
            mapControl.spriteNode.add_child(mapShovelSprite)

func PickShovel(open: bool) -> void :
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.packetPickControl):
        mapFeature.packetPickControl.PacketPickRelease()
    if open:
        AudioManager.AudioPlay("Shovel", AudioManagerEnum.TYPE.SFX)
        shovelPick = true
        mapShovelSprite.position = Vector2(-100, -100)
        mapShovelSprite.visible = true
    else:
        AudioManager.AudioPlay("ShovelDeny", AudioManagerEnum.TYPE.SFX)
        shovelPick = false
        mapShovelSprite.visible = false

func ProcessShovelPick(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    if mapShovelSprite:
        mapShovelSprite.visible = true
        if mapShovelSprite.texture:
            mapShovelSprite.scale = Vector2.ONE * 80.0 / mapShovelSprite.texture.get_width()
        if is_instance_valid(mapControl) && is_instance_valid(mapControl.spriteNode):
            mapShovelSprite.position = mapControl.spriteNode.get_local_mouse_position() - Vector2(-35.0, 35.0)
    if TowerDefenseManager.CheckMapGridPosIn(gridPos):
        var groundHeight: float = mapFeature.GetGroundHeight(cell)
        var cellPos: Vector2 = TowerDefenseManager.GetMapCellPos(gridPos)
        var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
        var offset: Vector2 = mousePos - cellPos + Vector2(0, groundHeight)
        var percentage: float = offset.y / gridSize.y
        var shovelPlant: TowerDefenseCharacter = cell.GetShovelCharacter(percentage)
        if shovelPlant != lastShovelPlant:
            if is_instance_valid(lastShovelPlant):
                lastShovelPlant.SetSpriteGroupShaderParameter("brightStrength", 0.0)
            lastShovelPlant = shovelPlant
        if shovelPlant:
            shovelPlant.Bright(0.5, 0.0)
        if cell.CanShovel(percentage):
            if mapControl.IsConfirmInput():
                AudioManager.AudioPlay("ShovelDig", AudioManagerEnum.TYPE.SFX)
                if Global.isMultiplayerMode:
                    MultiPlayerManager.SendRemovePlant(gridPos.x, gridPos.y)
                    cell.Shovel(shovelConfig, percentage)
                    mapFeature.packetPickControl.Release()
                elif !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
                    cell.Shovel(shovelConfig, percentage)
                    mapFeature.packetPickControl.Release()
                else:
                    cell.Shovel(TowerDefenseManager.GetShovel("ShovelDefault"), percentage)
                    LevelEditorMapEditor.instance.levelConfig.canExport = false
                lastShovelPlant = null
    else:
        if is_instance_valid(lastShovelPlant):
            lastShovelPlant.SetSpriteGroupShaderParameter("brightStrength", 0.0)
            lastShovelPlant = null

func ShovelRelease() -> void :
    if shovelPick:
        AudioManager.AudioPlay("ShovelDeny", AudioManagerEnum.TYPE.SFX)
    shovelPick = false
    if is_instance_valid(mapShovelSprite):
        mapShovelSprite.visible = false
    if is_instance_valid(shovelButton):
        shovelButton.button_pressed = false
    if is_instance_valid(lastShovelPlant):
        lastShovelPlant.SetSpriteGroupShaderParameter("brightStrength", 0.0)
        lastShovelPlant = null

func ShovelReset() -> void :
    shovelPick = false
    if is_instance_valid(mapShovelSprite):
        mapShovelSprite.visible = false
    if is_instance_valid(shovelButton):
        shovelButton.button_pressed = false
    if is_instance_valid(lastShovelPlant):
        lastShovelPlant.SetSpriteGroupShaderParameter("brightStrength", 0.0)
        lastShovelPlant = null

func Start() -> void :
    if !is_instance_valid(shovelButton):
        return
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        shovelButton.visible = false
    else:
        shovelButton.visible = true
