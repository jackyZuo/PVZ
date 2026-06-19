class_name PacketPickControl extends Node2D

var mapControl: TowerDefenseMapControl
var mapFeature: TowerDefenseBattleFeatureMap

var packetPick: TowerDefenseInGamePacketShow
var followSprite: AdobeAnimateSprite
var plantSpriteList: Array[AdobeAnimateSprite]
var selectPacketTimer: int = 0

var tools: Array[PacketPickTool] = []
var _wasPicking: bool = false
var _toolActivateGrace: int = 0

func Init(_mapControl: TowerDefenseMapControl, _mapFeature: TowerDefenseBattleFeatureMap) -> void :
    mapControl = _mapControl
    mapFeature = _mapFeature

func RegisterTool(tool: PacketPickTool) -> void :
    tools.append(tool)

func UnregisterTool(tool: PacketPickTool) -> void :
    tools.erase(tool)

func IsPicking() -> bool:
    for tool in tools:
        if tool.IsPicking():
            return true
    return is_instance_valid(packetPick)

func CreatePreviewSprite(characterConfig: TowerDefenseCharacterConfig, packetConfig) -> AdobeAnimateSprite:
    var sprite: AdobeAnimateSprite = TowerDefenseManager.GetCharacterSprite(characterConfig.name)
    sprite.light_mask = 0
    sprite.modulate.a = 0.5
    sprite.z_index = 900
    sprite.position = Vector2(-100, -100)
    if packetConfig.packetFlip:
        sprite.scale.x = - sprite.scale.x
    sprite.meshColor.a = 0.5
    return sprite

func FreePreviewSprites() -> void :
    if is_instance_valid(followSprite):
        followSprite.queue_free()
        followSprite = null
    for sprite in plantSpriteList:
        if is_instance_valid(sprite):
            sprite.queue_free()
    plantSpriteList.clear()

func ApplyArmorSprite(sprite: AdobeAnimateSprite, armor: CharacterArmorConfig) -> void :
    var slotNode: AdobeAnimateSlot = sprite.get_node(armor.replaceSpriteSlotPath)
    var armorSprite: Sprite2D = Sprite2D.new()
    armorSprite.texture = armor.stageAnimeTexture[0]
    armorSprite.position = armor.replaceSpriteOffset
    armorSprite.rotation = armor.replaceSpriteRotation
    armorSprite.scale = armor.replaceSpriteScale
    slotNode.add_child(armorSprite)

@warning_ignore("unused_parameter")
func ProcessPacketPick(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> bool:
    var limitPlantGridNum: int = -1
    if is_instance_valid(TowerDefenseManager.currentControl):
        limitPlantGridNum = TowerDefenseManager.currentControl.levelConfig.limitGridPlantNum
    if selectPacketTimer > 0:
        selectPacketTimer -= 1
        return true
    if followSprite:
        followSprite.visible = true
        if is_instance_valid(mapControl) && is_instance_valid(mapControl.spriteNode):
            followSprite.position = mapControl.spriteNode.get_local_mouse_position() - Vector2(0.0, 20.0)
    for sprite in plantSpriteList:
        sprite.visible = false
    if is_instance_valid(cell):
        var plantFlag: bool = true
        if !TowerDefenseManager.CheckMapGridPosIn(gridPos):
            plantFlag = false
        if packetPick.config.IsLimitGridNum():
            if !(limitPlantGridNum == -1 || (limitPlantGridNum > mapFeature.GetCellPlantNum() || cell.HasPlant())):
                plantFlag = false
        if packetPick.config.characterConfig is TowerDefenseZombieConfig:
            plantFlag = true
        if !cell.CanPacketPlant(packetPick.config):
            plantFlag = false
        if (packetPick.config.characterConfig is TowerDefensePlantConfig || packetPick.config.characterConfig is TowerDefenseZombieConfig) && mapFeature.strigeRow != -1:
            if (packetPick.config.characterConfig is TowerDefensePlantConfig || packetPick.config.izmPlantLeft) && mapFeature.strigeRow < gridPos.x:
                plantFlag = false
            if (packetPick.config.characterConfig is TowerDefenseZombieConfig && !packetPick.config.izmPlantLeft) && mapFeature.strigeRow >= gridPos.x:
                plantFlag = false
        if TowerDefenseManager.IsIZMMode():
            if packetPick.config.izmPlantAllCell:
                plantFlag = true
        if plantFlag:
            if !mapFeature.isPlantColumn:
                var plantPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(gridPos)
                var groundHeight: float = mapFeature.GetGroundHeight(cell)
                if plantSpriteList.size() > 0:
                    plantSpriteList[0].visible = true
                    plantSpriteList[0].global_position = plantPos - Vector2(0.0, groundHeight)
                if mapControl.IsConfirmInput():
                    if Global.isMultiplayerMode:
                        var _override_data: String = ""
                        if is_instance_valid(packetPick.config.override):
                            _override_data = JSON.stringify(packetPick.config.override.Export())
                        if MultiPlayerManager.isHost:
                            var sync_id: int = TowerDefenseManager.currentControl._get_next_sync_id()
                            var character = packetPick.Plant(gridPos)
                            if is_instance_valid(character):
                                TowerDefenseManager.currentControl._register_sync_character(sync_id, character)
                                MultiPlayerManager.SendPlacePlant(packetPick.config.saveKey, gridPos.x, gridPos.y, sync_id, _override_data)
                        else:
                            if packetPick.has_meta("packet_sync_id"):
                                packetPick.set_meta("packet_planted", true)
                            packetPick.Use()
                            MultiPlayerManager.SendPlacePlant(packetPick.config.saveKey, gridPos.x, gridPos.y, -1, _override_data)
                        if !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
                            Release()
                        else:
                            LevelEditorMapEditor.instance.levelConfig.canExport = false
                    else:
                        packetPick.Plant(gridPos)
                        if !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
                            Release()
                        else:
                            LevelEditorMapEditor.instance.levelConfig.canExport = false
            else:
                for i in mapFeature.config.gridNum.y:
                    var plantPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(Vector2(gridPos.x, i + 1))
                    var getCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(Vector2(gridPos.x, i + 1))
                    if getCell.CanPacketPlant(packetPick.config):
                        var groundHeight: float = mapFeature.GetGroundHeight(getCell)
                        if plantSpriteList.size() > i:
                            var sprite: AdobeAnimateSprite = plantSpriteList[i]
                            sprite.visible = true
                            sprite.global_position = plantPos - Vector2(0.0, groundHeight)
                if mapControl.IsConfirmInput():
                    if Global.isMultiplayerMode:
                        var _override_data: String = ""
                        if is_instance_valid(packetPick.config.override):
                            _override_data = JSON.stringify(packetPick.config.override.Export())
                        if MultiPlayerManager.isHost:
                            var sync_ids: Array = []
                            for i in mapFeature.config.gridNum.y:
                                sync_ids.append(TowerDefenseManager.currentControl._get_next_sync_id())
                            for i in mapFeature.config.gridNum.y:
                                var character = packetPick.Plant(Vector2(gridPos.x, i + 1), i == 0, i == mapFeature.config.gridNum.y - 1)
                                if is_instance_valid(character):
                                    TowerDefenseManager.currentControl._register_sync_character(sync_ids[i], character)
                                    MultiPlayerManager.SendPlacePlant(packetPick.config.saveKey, gridPos.x, i + 1, sync_ids[i], _override_data)
                        else:
                            if packetPick.has_meta("packet_sync_id"):
                                packetPick.set_meta("packet_planted", true)
                            packetPick.Use()
                            for i in mapFeature.config.gridNum.y:
                                MultiPlayerManager.SendPlacePlant(packetPick.config.saveKey, gridPos.x, i + 1, -1, _override_data)
                        if !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
                            Release()
                        else:
                            LevelEditorMapEditor.instance.levelConfig.canExport = false
                    else:
                        for i in mapFeature.config.gridNum.y:
                            packetPick.Plant(Vector2(gridPos.x, i + 1), i == 0, i == mapFeature.config.gridNum.y - 1)
                        if !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
                            Release()
                        else:
                            LevelEditorMapEditor.instance.levelConfig.canExport = false
    return false

func ProcessTools(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    for tool in tools:
        if tool.IsPicking():
            tool.ProcessPick(cell, gridPos, mousePos)
    var currentlyPicking: bool = IsPicking()
    if currentlyPicking && !_wasPicking:
        _toolActivateGrace = 5
    _wasPicking = currentlyPicking

func PickPacket(_packet: TowerDefenseInGamePacketShow) -> void :
    var characterConfig: TowerDefenseCharacterConfig = _packet.config.characterConfig
    selectPacketTimer = 5
    for tool in tools:
        tool.ToolReset()
    if _packet.select:
        if is_instance_valid(packetPick) && packetPick != _packet:
            PacketPickRelease()
        packetPick = _packet
        if Global.isMultiplayerMode and _packet.has_meta("packet_sync_id"):
            var sync_id: int = _packet.get_meta("packet_sync_id")
            MultiPlayerManager.SendPacketPick(sync_id, "lock")
        var characters = TowerDefenseManager.GetCharacter()
        for character: TowerDefenseCharacter in characters:
            character.SetSpriteGroupShaderParameter("cover", false)
        for character: TowerDefenseCharacter in characters:
            var passes_filter: = true
            if character is TowerDefensePlant && is_instance_valid(character.cell):
                if !character.cell.CanPacketPlant(packetPick.config):
                    passes_filter = false
            if passes_filter && character is TowerDefensePlant && is_instance_valid(character.cell):
                if characterConfig is TowerDefensePlantConfig && !characterConfig.extendCoverDictionary.is_empty():
                    for pos: Vector2i in characterConfig.extendCoverDictionary.keys():
                        var extCell = TowerDefenseManager.GetMapCell(character.cell.gridPos + pos)
                        if !is_instance_valid(extCell):
                            continue
                        for _character in extCell.GetCharacterList():
                            if _character.config.name == characterConfig.extendCoverDictionary[pos]:
                                _character.SetSpriteGroupShaderParameter("cover", true)
            if passes_filter:
                if !packetPick.config.GetPlantCover().is_empty() && packetPick.config.GetPlantCover().has(character.config.name):
                    character.SetSpriteGroupShaderParameter("cover", true)

        FreePreviewSprites()

        followSprite = TowerDefenseManager.GetCharacterSprite(characterConfig.name)
        followSprite.light_mask = 0
        followSprite.z_index = 1000
        followSprite.position = Vector2(-100, -100)
        if _packet.config.packetFlip:
            followSprite.scale.x = - followSprite.scale.x

        var sprite_count: = mapFeature.config.gridNum.y if mapFeature.isPlantColumn else 1
        for i in sprite_count:
            plantSpriteList.append(CreatePreviewSprite(characterConfig, _packet.config))

        if characterConfig.armorData:
            if _packet.config.initArmor.size() > 0:
                for armorName: String in _packet.config.initArmor:
                    var armor: CharacterArmorConfig = characterConfig.armorData.armorDictionary[armorName]
                    match armor.replaceMethod:
                        "Media":
                            characterConfig.armorData.OpenArmorFliters(followSprite, armorName)
                            characterConfig.armorData.SetArmorReplace(followSprite, armorName, 0)
                            for sprite in plantSpriteList:
                                characterConfig.armorData.OpenArmorFliters(sprite, armorName)
                                characterConfig.armorData.SetArmorReplace(sprite, armorName, 0)
                        "Sprite":
                            ApplyArmorSprite(followSprite, armor)
                            for sprite in plantSpriteList:
                                ApplyArmorSprite(sprite, armor)

        if characterConfig.customData:
            var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue(_packet.config.saveKey)
            if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
                characterConfig.customData.SetCustomFliters(followSprite, packetValue["Key"]["Custom"])
                for sprite in plantSpriteList:
                    characterConfig.customData.SetCustomFliters(sprite, packetValue["Key"]["Custom"])

        mapControl.spriteNode.add_child(followSprite)
        for sprite in plantSpriteList:
            mapControl.spriteNode.add_child(sprite)
    else:
        if _packet.canPressPutBack:
            Release()

func Release() -> void :
    for tool in tools:
        tool.ToolRelease()
    PacketPickRelease()

func ProcessReleaseInput(mousePos: Vector2) -> void :
    if _toolActivateGrace > 0:
        _toolActivateGrace -= 1
        return
    if !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
        if Global.isMobile:
            if Input.is_action_just_pressed("Press"):
                if IsPicking():
                    if is_instance_valid(mapControl) && !mapFeature.groundRect.has_point(mousePos):
                        Release()
            if Input.is_action_just_released("Press"):
                if !IsPicking():
                    for sprite in plantSpriteList:
                        if is_instance_valid(sprite):
                            sprite.visible = false
                    if is_instance_valid(followSprite):
                        followSprite.visible = false
                    for tool in tools:
                        var mapSprite: Node2D = tool.GetMapSprite()
                        if is_instance_valid(mapSprite):
                            mapSprite.visible = false
        else:
            if Input.is_action_just_pressed("Release"):
                Release()
    else:
        if Input.is_action_just_pressed("Release"):
            Release()

func PacketPickRelease() -> void :
    if is_instance_valid(packetPick):
        if Global.isMultiplayerMode and packetPick.has_meta("packet_sync_id"):
            var sync_id: int = packetPick.get_meta("packet_sync_id")
            if packetPick.has_meta("packet_planted"):
                MultiPlayerManager.SendPacketPick(sync_id, "remove")
            else:
                MultiPlayerManager.SendPacketPick(sync_id, "unlock")
        for character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
            character.SetSpriteGroupShaderParameter("cover", false)
        packetPick.Reset()
        packetPick = null
    FreePreviewSprites()
