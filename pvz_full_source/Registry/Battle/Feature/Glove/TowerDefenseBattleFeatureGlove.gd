class_name TowerDefenseBattleFeatureGlove extends TowerDefenseBattleFeature

const GLOVE_MANAGER = preload("uid://d2i0ohax0btl4")

var gloveManager: GloveManager
var glovePickTool: GlovePickTool
var glovePick: bool = false
var pickedCharacter: TowerDefenseCharacter = null
var sourceGridPos: Vector2i = Vector2i.ZERO
var sourceCell: TowerDefenseCellInstance = null



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    gloveManager = GLOVE_MANAGER.instantiate()
    control.AddUIToTopPropContainer(gloveManager)

func GameInit() -> void :
    if !is_instance_valid(gloveManager):
        return
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    mapFeature.gloveManager = gloveManager
    gloveManager.Init(mapControl, mapFeature)

func GameInitFromProgress() -> void :
    if !is_instance_valid(gloveManager):
        return
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    mapFeature.gloveManager = gloveManager
    gloveManager.Init(mapControl, mapFeature)

func GameStart() -> void :
    if !is_instance_valid(gloveManager):
        return
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.packetPickControl):
        glovePickTool = GlovePickTool.new()
        glovePickTool.Init(mapControl)
        glovePickTool.SetGloveFeature(self)
        mapFeature.packetPickControl.RegisterTool(glovePickTool)

func Process(_delta: float) -> void :
    if !is_instance_valid(gloveManager):
        return
    gloveManager.UpdateDisplay()
    if glovePick:
        var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
        if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.mapControl):
            gloveManager.UpdateGloveSprite(mapFeature.mapControl)
    if !is_instance_valid(pickedCharacter):
        return
    if is_instance_valid(gloveManager.previewSprite):
        gloveManager.previewSprite.visible = true
        var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
        if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.mapControl):
            var mouseGlobalPos: Vector2 = mapFeature.mapControl.get_global_mouse_position()
            var gridPos: Vector2i = TowerDefenseManager.GetMapGridPosFromMouse(mouseGlobalPos)
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
            var canPlace: bool = false
            if gridPos != sourceGridPos && TowerDefenseManager.CheckMapGridPosIn(gridPos) && is_instance_valid(cell):
                if is_instance_valid(pickedCharacter) && is_instance_valid(pickedCharacter.packet):
                    canPlace = cell.CanPacketPlant(pickedCharacter.packet)
            if canPlace:
                var plantPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(gridPos)
                gloveManager.previewSprite.global_position = plantPos
            else:
                gloveManager.previewSprite.position = mapFeature.mapControl.spriteNode.get_local_mouse_position() - Vector2(0.0, 20.0)



func PickGlove(open: bool) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.packetPickControl):
        mapFeature.packetPickControl.PacketPickRelease()
    if open:
        AudioManager.AudioPlay("Shovel", AudioManagerEnum.TYPE.SFX)
        glovePick = true
        gloveManager.ShowMapGloveSprite(true)
        gloveManager.SetMapGloveSpritePos(Vector2(-100, -100))
    else:
        AudioManager.AudioPlay("ShovelDeny", AudioManagerEnum.TYPE.SFX)
        glovePick = false
        gloveManager.ShowMapGloveSprite(false)
        ClearPickedState()

func ProcessGlovePick(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    if !is_instance_valid(pickedCharacter):
        ProcessGloveSelect(cell, gridPos, mousePos)
    else:
        ProcessGlovePlace(cell, gridPos, mousePos)

func ProcessGloveSelect(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    if !TowerDefenseManager.CheckMapGridPosIn(gridPos):
        return
    if !is_instance_valid(cell):
        return
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    var groundHeight: float = mapFeature.GetGroundHeight(cell)
    var cellPos: Vector2 = TowerDefenseManager.GetMapCellPos(gridPos)
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var offset: Vector2 = mousePos - cellPos + Vector2(0, groundHeight)
    var percentage: float = offset.y / gridSize.y
    var glovePlant: TowerDefenseCharacter = cell.GetShovelCharacter(percentage)
    if glovePlant:
        glovePlant.Bright(0.5, 0.0)
    if cell.CanShovel(percentage) && glovePlant is TowerDefensePlant:
        if is_instance_valid(gloveManager) && gloveManager.mapControl.IsConfirmInput():
            SelectCharacter(glovePlant, cell, gridPos)

@warning_ignore("unused_parameter")
func ProcessGlovePlace(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    if gridPos == sourceGridPos:
        return
    if !TowerDefenseManager.CheckMapGridPosIn(gridPos):
        return
    if !is_instance_valid(cell):
        return
    var canPlace: bool = false
    if is_instance_valid(pickedCharacter) && is_instance_valid(pickedCharacter.packet):
        canPlace = cell.CanPacketPlant(pickedCharacter.packet)
    if canPlace:
        var plantPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(gridPos)
        if is_instance_valid(gloveManager) && is_instance_valid(gloveManager.previewSprite):
            gloveManager.previewSprite.global_position = plantPos
        if is_instance_valid(gloveManager) && gloveManager.mapControl.IsConfirmInput():
            PlaceCharacter(cell, gridPos)

func SelectCharacter(character: TowerDefenseCharacter, cell: TowerDefenseCellInstance, gridPos: Vector2i) -> void :
    pickedCharacter = character
    sourceGridPos = gridPos
    sourceCell = cell
    AudioManager.AudioPlay("ShovelDig", AudioManagerEnum.TYPE.SFX)
    gloveManager.CreatePreviewSprite(character)

func PlaceCharacter(targetCell: TowerDefenseCellInstance, targetGridPos: Vector2i) -> void :
    if !is_instance_valid(pickedCharacter):
        ClearPickedState()
        return
    var oldGlobalPosition: Vector2 = pickedCharacter.global_position
    sourceCell.RemoveCharacter(pickedCharacter)
    targetCell.CharacterPlant(pickedCharacter.packet, pickedCharacter, true)
    var plantPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(targetGridPos)
    pickedCharacter.global_position = plantPos
    pickedCharacter.gridPos = targetGridPos
    pickedCharacter.groundHeight = targetCell.GetGroundHeight(0.5)
    pickedCharacter.z = pickedCharacter.groundHeight
    if is_instance_valid(pickedCharacter.shadowComponent):
        pickedCharacter.shadowComponent.saveShadowPosition = pickedCharacter.shadowComponent.saveShadowPosition + plantPos - oldGlobalPosition
        pickedCharacter.shadowComponent.SetVisible( !pickedCharacter.invisible)
    AudioManager.AudioPlay("ShovelDig", AudioManagerEnum.TYPE.SFX)
    ClearPickedState()
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.packetPickControl):
        mapFeature.packetPickControl.Release()

func ClearPickedState() -> void :
    pickedCharacter = null
    sourceCell = null
    sourceGridPos = Vector2i.ZERO
    gloveManager.FreePreviewSprite()

func GloveRelease() -> void :
    if glovePick:
        AudioManager.AudioPlay("ShovelDeny", AudioManagerEnum.TYPE.SFX)
    ClearPickedState()
    glovePick = false
    gloveManager.ShowMapGloveSprite(false)
    gloveManager.SetGloveButtonPressed(false)

func GloveReset() -> void :
    ClearPickedState()
    glovePick = false
    gloveManager.ShowMapGloveSprite(false)
    gloveManager.SetGloveButtonPressed(false)

func GloveButtonPressed() -> void :
    if !gloveManager.gloveShow && !TowerDefenseManager.currentControl.isGameRunning:
        gloveManager.SetGloveButtonPressed(false)
        return
    if gloveManager.glovePressedAwait:
        return
    ClearPickedState()
    PickGlove(gloveManager.IsGloveButtonPressed())
    gloveManager.glovePressedAwait = true
    await control.get_tree().create_timer(0.1, false).timeout
    gloveManager.glovePressedAwait = false
