class_name TowerDefenseCellInstance extends Resource

const SURROUND_INCLUDE_GRID: Array[TowerDefenseEnum.PLANTGRIDTYPE] = [TowerDefenseEnum.PLANTGRIDTYPE.SOIL, TowerDefenseEnum.PLANTGRIDTYPE.BRICK, TowerDefenseEnum.PLANTGRIDTYPE.WATER]

@export var gridType: Array[TowerDefenseEnum.PLANTGRIDTYPE] = [TowerDefenseEnum.PLANTGRIDTYPE.GROUND, TowerDefenseEnum.PLANTGRIDTYPE.AIR]
@export var elementFlags: int = 0
@export var isWater: bool = false
var characterList: Array[TowerDefenseCharacter]
var characterSlotDictionary: Dictionary[TowerDefenseCharacter, TowerDefenseCharacter] = {}
var slot: Dictionary[TowerDefenseEnum.PLANTGRIDTYPE, TowerDefenseCharacter] = {}
var characterSurround: TowerDefenseCharacter
var characterLadder: TowerDefenseCharacter

var itemShield: TowerDefenseItemSheild
var gridPos: Vector2i = Vector2i.ZERO
var groundHeightCurve: CurveTexture
var config: TowerDefenseCellConfig
var _dirty: bool = false

func Init(_config: TowerDefenseCellConfig) -> void :
    config = _config
    gridType = config.gridType.duplicate(true)
    elementFlags = config.elementFlags
    characterList.clear()
    characterSlotDictionary.clear()
    slot.clear()
    groundHeightCurve = config.groundHeightCurve
    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        slot[type] = null

func Clear() -> void :
    var clearList: Array = []
    for i in characterList.size():
        clearList.append(characterList[i])
    for character in clearList:
        if is_instance_valid(character):
            character.Destroy()
    for slotType: TowerDefenseEnum.PLANTGRIDTYPE in slot.keys():
        if is_instance_valid(slot[slotType]):
            slot[slotType].Destroy()
        slot[slotType] = null
    characterList.clear()
    characterSlotDictionary.clear()
    if is_instance_valid(characterSurround):
        characterSurround.Destroy()
    if is_instance_valid(characterLadder):
        characterLadder.Destroy()
    _dirty = false

func ClearEmpty() -> void :
    if !_dirty:
        return
    _dirty = false
    var i: int = characterList.size() - 1
    while i >= 0:
        if !is_instance_valid(characterList[i]):
            characterList.remove_at(i)
        i -= 1
    for key in characterSlotDictionary.keys():
        if !is_instance_valid(key):
            characterSlotDictionary.erase(key)
    if !is_instance_valid(characterSurround):
        characterSurround = null
    if !is_instance_valid(characterLadder):
        characterLadder = null
    if !is_instance_valid(itemShield):
        itemShield = null

func CharacterPlant(packetConfig: TowerDefensePacketConfig, character: TowerDefenseCharacter, noLimit: bool = false) -> void :
    ClearEmpty()



    var nutBandaging: bool = GameSaveManager.GetFeatureValue("NutBandaging") > 0
    var potReplacement: bool = GameSaveManager.GetFeatureValue("PotReplacement") > 0
    var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
    if characterConfig is TowerDefenseItemConfig:
        if characterConfig.isLadder:
            if HasWallnut():
                characterLadder = character
                characterList.append(character)
                characterSlotDictionary[character] = null
                character.destroy.connect(CharacterDestroy)
                return

    if character is TowerDefenseItemSheild:
        if is_instance_valid(itemShield):
            itemShield.ShieldAddHitpoints(TowerDefenseItemSheild.HP_PER_LAYER, character.shieldType)
            character.queue_free()
            return
        else:
            itemShield = character
            characterList.append(character)
            characterSlotDictionary[character] = null
            if !character.destroy.is_connected(CharacterDestroy):
                character.destroy.connect(CharacterDestroy)
            return



    if is_instance_valid(itemShield) && character is TowerDefensePlant:
        itemShield.instance.canBeCollection = false

    if !packetConfig.GetPlantCover().is_empty():
        if !noLimit:
            for _character: TowerDefenseCharacter in characterList:
                if !is_instance_valid(_character):
                    continue
                if packetConfig.GetPlantCover().has(_character.config.name):
                    if !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
                        var findId = packetConfig.GetPlantCover().find(_character.config.name)
                        if characterConfig.plantCoverRecycle.size() > findId:
                            if is_instance_valid(_character.instance) && _character.instance.hypnoses && _character is TowerDefensePlant:
                                character.BrainSunCreate(character.global_position, characterConfig.plantCoverRecycle[findId], TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                            else:
                                character.SunCreate(character.global_position, characterConfig.plantCoverRecycle[findId], TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
                    CharacterReplace(_character, character)
                    return

    if characterConfig is TowerDefensePlantConfig:
        if !characterConfig.extendCoverDictionary.keys().is_empty():
            var hasCover: bool = false
            for posKey: Vector2i in characterConfig.extendCoverDictionary.keys():
                var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + posKey)
                if is_instance_valid(cell):
                    for _character: TowerDefenseCharacter in cell.characterList:
                        if !is_instance_valid(_character):
                            continue
                        if _character.config.name == characterConfig.extendCoverDictionary[posKey]:
                            cell.CharacterReplace(_character, character)
                            hasCover = true
                            break
            if hasCover:
                return

    if packetConfig.characterConfig.plantCoverSelf:
        for _character: TowerDefenseCharacter in characterList:
            if _character.config.name == packetConfig.characterConfig.name:
                CharacterReplace(_character, character)
                return

    if characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SURROUND):
        if !is_instance_valid(characterSurround):
            characterSurround = character
            characterList.append(character)
            characterSlotDictionary[character] = null
            character.destroy.connect(CharacterDestroy)
            return

    if nutBandaging && characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
        for _character: TowerDefenseCharacter in characterList:
            if !is_instance_valid(_character):
                continue
            if characterConfig.name != _character.config.name:
                continue
            if !_character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
                continue
            if _character.instance.damagePointIndex <= 1:
                continue
            CharacterReplace(_character, character)
            return

    if potReplacement:
        if characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT:
            for _character: TowerDefenseCharacter in characterList:
                if !is_instance_valid(_character):
                    continue
                if characterConfig.name == _character.config.name:
                    continue
                if !_character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT:
                    continue
                if _character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NO_POT_REPLACE:
                    if IsWater():
                        continue
                CharacterReplace(_character, character)
                return
    if characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
            for _character: TowerDefenseCharacter in characterList:
                if !is_instance_valid(_character):
                    continue
                if characterConfig.name == _character.config.name:
                    continue
                if !_character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
                    continue
                CharacterReplace(_character, character)
                return

    characterList.append(character)

    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        if !slot.has(type):
            continue
        if is_instance_valid(slot[type]):
            if characterConfig.plantGridType.has(type):
                var isPlantCharacter: TowerDefenseCharacter = slot[type]
                var isPlantCharacterConfig: TowerDefenseCharacterConfig = isPlantCharacter.config
                if isPlantCharacterConfig.plantGridType.has(characterConfig.plantGridOverrideType):
                    slot[type] = character
                    characterSlotDictionary[character] = isPlantCharacter
                    break

    characterSlotDictionary[character] = null
    if !character.destroy.is_connected(CharacterDestroy):
        character.destroy.connect(CharacterDestroy)

    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        if characterConfig.plantGridType.has(type):
            if !slot.has(type):
                continue
            if !is_instance_valid(slot[type]):
                slot[type] = character
                return

    var slotCharacter: TowerDefenseCharacter = GetCharacterWhoHasGridType(packetConfig)
    if is_instance_valid(slotCharacter):
        characterSlotDictionary[slotCharacter] = character
    return

func CharacterReplace(character: TowerDefenseCharacter, replaceCharacter: TowerDefenseCharacter) -> void :
    ClearEmpty()
    replaceCharacter.destroy.connect(CharacterDestroy)
    characterList.append(replaceCharacter)
    characterSlotDictionary[replaceCharacter] = characterSlotDictionary[character]
    var flag: bool = false
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        flag = true
    if characterSurround == character:
        characterSurround = replaceCharacter
        replaceCharacter.Cover(character)
    for slotCharacter: TowerDefenseCharacter in characterSlotDictionary.keys():
        if characterSlotDictionary[slotCharacter] == character:
            if !flag:
                replaceCharacter.Cover(character)
                flag = true
            characterSlotDictionary[slotCharacter] = replaceCharacter
    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        if !slot.has(type):
            continue
        if is_instance_valid(slot[type]):
            if slot[type] == character:
                if !flag:
                    replaceCharacter.Cover(character)
                    flag = true
                slot[type] = replaceCharacter
                break
    character.Destroy()

func CharacterDestroy(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character):
        return
    if characterSlotDictionary.has(character):
        if is_instance_valid(characterSlotDictionary[character]):
            for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
                if characterSlotDictionary[character].config.plantGridType.has(type):
                    if !is_instance_valid(slot[type]) || slot[type] == character:
                        slot[type] = characterSlotDictionary[character]
                        break

    if character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
        if is_instance_valid(characterLadder):
            characterLadder.Destroy()

    for characterKey in characterSlotDictionary.keys():
        if !is_instance_valid(characterSlotDictionary[characterKey]) || characterSlotDictionary[characterKey] == character:
            characterSlotDictionary[characterKey] = null

    for slotKey in slot.keys():
        if !is_instance_valid(slot[slotKey]) || slot[slotKey] == character:
            slot[slotKey] = null

    characterList.erase(character)

    characterSlotDictionary.erase(character)
    if characterSurround == character:
        characterSurround = null
    if characterLadder == character:
        characterLadder = null
    if itemShield == character:
        itemShield = null
        _dirty = true


    if is_instance_valid(itemShield) && character is TowerDefensePlant:
        if !HasSlotCharacterList() && !is_instance_valid(characterSurround):
            itemShield.instance.canBeCollection = true
    return

func GetSlotCharacterList() -> Array[TowerDefenseCharacter]:
    ClearEmpty()
    var characterListGet: Array[TowerDefenseCharacter] = []
    for type in SURROUND_INCLUDE_GRID:
        if gridType.has(type) && slot.has(type) && is_instance_valid(slot[type]):
            characterListGet.append(slot[type])
    return characterListGet

func HasSlotCharacterList() -> bool:
    return !GetSlotCharacterList().is_empty()

func GetCharacterListSave(checkSlot: bool = true) -> Array[TowerDefenseCharacter]:
    ClearEmpty()
    var excludeCharacterList: Array[TowerDefenseCharacter] = []
    var characterListGet: Array[TowerDefenseCharacter] = []
    if checkSlot:
        characterListGet.append_array(GetSlotCharacterList())
    else:
        excludeCharacterList.append_array(GetSlotCharacterList())
    for character: TowerDefenseCharacter in characterList:
        if excludeCharacterList.has(character):
            continue
        if characterListGet.has(character):
            continue
        if character == characterLadder:
            continue
        if character == characterSurround:
            continue
        characterListGet.append(character)
    if is_instance_valid(characterSurround):
        characterListGet.append(characterSurround)
    if is_instance_valid(characterLadder):
        characterListGet.append(characterLadder)
    return characterListGet

func GetCharacterList() -> Array[TowerDefenseCharacter]:
    return characterList

func GetGridType() -> Array[TowerDefenseEnum.PLANTGRIDTYPE]:
    return gridType

func GetCharacterWhoHasGridType(packetConfig: TowerDefensePacketConfig) -> TowerDefenseCharacter:
    ClearEmpty()
    var _gridType: Array[TowerDefenseEnum.PLANTGRIDTYPE] = packetConfig.characterConfig.plantGridType
    for character: TowerDefenseCharacter in characterList:
        if !is_instance_valid(character) || is_instance_valid(characterSlotDictionary[character]):
            continue
        if character.instance.hologram:
            continue
        if character:
            var characterConfig: TowerDefenseCharacterConfig = character.config
            if characterConfig.plantGridOverrideType == TowerDefenseEnum.PLANTGRIDTYPE.NOONE:
                continue
            if characterConfig.plantGridOverrideType == packetConfig.characterConfig.plantGridOverrideType:
                continue
            if _gridType.has(characterConfig.plantGridOverrideType):
                return character
    return null

func CanPacketPlant(packetConfig: TowerDefensePacketConfig, noLimit: bool = false, isCheck: bool = false) -> bool:
    if packetConfig == null:
        return false
    ClearEmpty()
    var characterConfig: TowerDefenseCharacterConfig = packetConfig.characterConfig
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        if HasVase() && !(packetConfig.characterConfig is TowerDefenseVaseConfig):
            return true

    if !isCheck:
        if characterConfig is TowerDefensePlantConfig:
            if characterConfig.extendCoverDictionary.is_empty() || noLimit:
                for offset in characterConfig.extendGrid:
                    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + offset)
                    if !is_instance_valid(cell):
                        return false
                    if !cell.CanPacketPlant(packetConfig, noLimit, true):
                        return false

    if characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.ALL):
        return true

    if !isCheck:
        if characterConfig is TowerDefensePlantConfig:
            for _character: TowerDefenseCharacter in characterList:
                if !is_instance_valid(_character):
                    continue
                if _character.config is TowerDefensePlantConfig:
                    if !_character.config.extendGrid.is_empty() && _character.gridPos != gridPos:
                        if !_character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SURROUND):
                            return false

    if characterConfig is TowerDefenseItemConfig:
        if characterConfig.isLadder:
            return HasWallnut() && !is_instance_valid(characterLadder)

        if characterConfig.isShield:
            return true

    if !characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.ICECAP):
        var iceCap = TowerDefenseManager.GetMapIceCapList()[gridPos.y]
        if is_instance_valid(iceCap):
            if !characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.GRAVESTONE) && !characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
                if TowerDefenseManager.GetMapGridPos(iceCap.iceCapSprite.global_position).x <= gridPos.x:
                    return false

    if characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SURROUND):
        if !characterConfig.plantSurroundCanHasSlot:
            for character: TowerDefenseCharacter in characterList:
                if character.config.plantGridOverrideType != TowerDefenseEnum.PLANTGRIDTYPE.NOONE:
                    return false

    if !characterConfig.plantCanHasSurround:
        if is_instance_valid(characterSurround):
            return false

    if is_instance_valid(characterSurround):
        if characterConfig is TowerDefensePlantConfig && !characterConfig.extendGrid.is_empty():
            if characterSurround.config is TowerDefensePlantConfig && characterSurround.config.extendGrid.is_empty():
                return false

    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        if !slot.has(type):
            continue
        if is_instance_valid(slot[type]):
            if slot[type].instance.hypnoses != packetConfig.GetHypnoses() || slot[type].instance.hologram:
                continue
            if slot[type] is TowerDefenseGravestone:
                if !characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.GRAVESTONE) && !characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
                    return false
            if slot[type] is TowerDefenseCrater:
                if !characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR) && !characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.CRATER):
                    return false

    if !packetConfig.GetPlantCover().is_empty():
        if !noLimit:
            for character: TowerDefenseCharacter in characterList:
                if !is_instance_valid(character):
                    continue
                if character.instance.hypnoses != packetConfig.GetHypnoses() || character.instance.hologram:
                    continue
                if is_instance_valid(characterSlotDictionary[character]) && characterConfig.plantGridOverrideType != character.config.plantGridOverrideType:
                    continue
                if packetConfig.GetPlantCover().has(character.config.name):
                    return true
            if !packetConfig.GetCoverCanDirectPlant():
                return false

    if characterConfig is TowerDefensePlantConfig:
        if !noLimit:
            if !characterConfig.extendCoverDictionary.is_empty():
                for offset: Vector2i in characterConfig.extendCoverDictionary.keys():
                    var _cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + offset)

                    if !is_instance_valid(_cell):
                        return false
                    if !_cell.HasCharacter(characterConfig.extendCoverDictionary[offset]):
                        return false

                return true

    if packetConfig.characterConfig.plantCoverSelf:
        for character: TowerDefenseCharacter in characterList:
            if character.config.name == packetConfig.characterConfig.name:
                return true

    var nutBandaging: bool = GameSaveManager.GetFeatureValue("NutBandaging") > 0
    var potReplacement: bool = GameSaveManager.GetFeatureValue("PotReplacement") > 0

    if characterConfig.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SURROUND):
        var surroundPlantFlag: bool = true
        for character: TowerDefenseCharacter in characterList:
            if !is_instance_valid(character):
                continue
            if character.instance.hypnoses != packetConfig.GetHypnoses() || character.instance.hologram:
                continue
            if !character.config.plantCanHasSurround:
                return false
            if characterConfig is TowerDefensePlantConfig && characterConfig.extendGrid.is_empty():
                if character.config is TowerDefensePlantConfig && !character.config.extendGrid.is_empty():
                    return false
        if surroundPlantFlag:
            for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
                if !is_instance_valid(slot[type]):
                    if SURROUND_INCLUDE_GRID.has(type):
                        surroundPlantFlag = false
                        break;
                else:
                    if slot[type].instance.hypnoses != packetConfig.GetHypnoses() || slot[type].instance.hologram:
                        continue
                    if !slot[type].config.plantCanHasSurround:
                        surroundPlantFlag = false
                        break;
            for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
                if !slot.has(type):
                    continue
                if !is_instance_valid(slot[type]):
                    continue
                if slot[type].instance.hypnoses || slot[type].instance.hologram:
                    continue
                if characterConfig.plantSurroundCanPlantWater && type == TowerDefenseEnum.PLANTGRIDTYPE.WATER:
                    surroundPlantFlag = true
                    break
        if surroundPlantFlag:
            if !is_instance_valid(characterSurround):
                return true

    if nutBandaging && characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
        for character: TowerDefenseCharacter in characterList:
            if !is_instance_valid(character):
                continue
            if character.instance.hypnoses != packetConfig.GetHypnoses() || character.instance.hologram:
                continue
            if characterConfig.name != character.config.name:
                continue
            if !character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
                continue
            if character.instance.damagePointIndex <= 1:
                continue
            return true

    if potReplacement:
        if characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT:
            for character: TowerDefenseCharacter in characterList:
                if !is_instance_valid(character):
                    continue
                if character.instance.hypnoses != packetConfig.GetHypnoses() || character.instance.hologram:
                    continue
                if characterConfig.name == character.config.name:
                    continue
                if !character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT:
                    continue
                if character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NO_POT_REPLACE:
                    if IsWater():
                        continue
                return true
        if characterConfig.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
            for character: TowerDefenseCharacter in characterList:
                if !is_instance_valid(character):
                    continue
                if character.instance.hypnoses != packetConfig.GetHypnoses() || character.instance.hologram:
                    continue
                if characterConfig.name == character.config.name:
                    continue
                if !character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LILYPAD:
                    continue
                return true

    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        if !slot.has(type):
            continue
        if !is_instance_valid(slot[type]):
            continue
        if slot[type].instance.hypnoses != packetConfig.GetHypnoses() || slot[type].instance.hologram:
            continue
        if characterConfig.plantGridType.has(type):
            var isPlantCharacter: TowerDefenseCharacter = slot[type]
            var isPlantCharacterConfig: TowerDefenseCharacterConfig = isPlantCharacter.config
            if isPlantCharacterConfig.plantGridType.has(characterConfig.plantGridOverrideType):
                return true

    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        if !slot.has(type):
            continue
        if is_instance_valid(slot[type]):
            continue
        if characterConfig.plantGridType.has(type):
            return true

    if characterConfig is TowerDefensePlantConfig || characterConfig is TowerDefenseGravestoneConfig:
        if GetCharacterWhoHasGridType(packetConfig):
            return true

    return false

func RemoveCharacter(character: TowerDefenseCharacter) -> void :
    if !is_instance_valid(character):
        return
    ClearEmpty()
    if character.destroy.is_connected(CharacterDestroy):
        character.destroy.disconnect(CharacterDestroy)
    if characterSlotDictionary.has(character):
        if is_instance_valid(characterSlotDictionary[character]):
            for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
                if characterSlotDictionary[character].config.plantGridType.has(type):
                    if !is_instance_valid(slot[type]) || slot[type] == character:
                        slot[type] = characterSlotDictionary[character]
                        break
    for characterKey in characterSlotDictionary.keys():
        if !is_instance_valid(characterSlotDictionary[characterKey]) || characterSlotDictionary[characterKey] == character:
            characterSlotDictionary[characterKey] = null
    for slotKey in slot.keys():
        if !is_instance_valid(slot[slotKey]) || slot[slotKey] == character:
            slot[slotKey] = null
    characterList.erase(character)
    characterSlotDictionary.erase(character)
    if characterSurround == character:
        characterSurround = null
    if characterLadder == character:
        characterLadder = null
    _dirty = true

func CanShovel(pecentage: float, shovelConfig: ShovelConfig = null) -> bool:
    return GetShovelCharacter(pecentage, shovelConfig) != null

func _IsShovelable(character: TowerDefenseCharacter, shovelConfig: ShovelConfig = null) -> bool:
    if character is TowerDefenseGravestone || character is TowerDefenseCrater:
        if is_instance_valid(shovelConfig) && !shovelConfig.shovelableNames.is_empty():
            if shovelConfig.shovelableNames.has(character.config.name):
                return true
        if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
            return true
        return false
    if character.instance.hypnoses || character.instance.hologram:
        return false
    return true

func GetShovelCharacter(pecentage: float, shovelConfig: ShovelConfig = null) -> TowerDefenseCharacter:
    ClearEmpty()
    if pecentage < 0.25:
        if gridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
            if is_instance_valid(slot[TowerDefenseEnum.PLANTGRIDTYPE.AIR]):
                if _IsShovelable(slot[TowerDefenseEnum.PLANTGRIDTYPE.AIR], shovelConfig):
                    return slot[TowerDefenseEnum.PLANTGRIDTYPE.AIR]
    if pecentage > 0.5:
        if is_instance_valid(characterSurround):
            if _IsShovelable(characterSurround, shovelConfig):
                return characterSurround

    for characterKey: TowerDefenseCharacter in characterSlotDictionary.keys():
        if is_instance_valid(characterSlotDictionary[characterKey]):
            if _IsShovelable(characterSlotDictionary[characterKey], shovelConfig):
                return characterSlotDictionary[characterKey]
    for characterKey: TowerDefenseEnum.PLANTGRIDTYPE in slot.keys():
        if is_instance_valid(slot[characterKey]):
            if _IsShovelable(slot[characterKey], shovelConfig):
                return slot[characterKey]
    for character: TowerDefenseCharacter in characterList:
        if _IsShovelable(character, shovelConfig):
            return character
    if is_instance_valid(characterSurround):
        if _IsShovelable(characterSurround, shovelConfig):
            return characterSurround
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        for character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
            if character.gridPos == gridPos:
                if _IsShovelable(character, shovelConfig):
                    return character
    return null

func Shovel(shovelConfig: ShovelConfig, pecentage: float) -> void :
    var character: TowerDefenseCharacter = GetShovelCharacter(pecentage, shovelConfig)
    if character:
        if character is TowerDefenseCrater:
            if (Global.isEditor && SceneManager.currentScene == "LevelEditorStage"):
                character.Destroy()
            else:
                character.DieDown()
            ClearEmpty()
            return
        if character is TowerDefensePlant || character is TowerDefenseItemSheild || (Global.isEditor && SceneManager.currentScene == "LevelEditorStage"):
            var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
            var plantedEffect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(load("uid://du8ukldfc7fh7"), character.gridPos)
            characterNode.add_child(plantedEffect)
            plantedEffect.global_position = character.transformPoint.global_position
            shovelConfig.Execute(character)
            ClearEmpty()
            return































func _IsValidTarget(character: TowerDefenseCharacter, camp: TowerDefenseEnum.CHARACTER_CAMP, maskFlags: int, checkInvincible: bool) -> bool:
    if character is TowerDefenseGravestone:
        return false
    if character is TowerDefenseCrater:
        return false
    if character is TowerDefenseVase:
        return false
    if checkInvincible && character.instance.invincible:
        return false
    if !character.instance.canBeCollection:
        return false
    if !is_instance_valid(character.hitBox):
        return false
    if !character.CheckDifferentCamp(camp):
        return false
    if !character.CanCollision(maskFlags):
        return false
    if !(character.instance.maskFlags & maskFlags):
        return false
    return true

func GetTarget(maskFlags: int = 0, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT, checkInvincible: bool = true, isCataplut: bool = false) -> TowerDefenseCharacter:
    ClearEmpty()
    if !isCataplut:
        if is_instance_valid(characterSurround):
            if characterSurround.instance.canBeCollection:
                if characterSurround.CanCollision(maskFlags):
                    if characterSurround.instance.maskFlags & maskFlags:
                        return characterSurround
    if isCataplut:
        if slot.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
            if is_instance_valid(slot[TowerDefenseEnum.PLANTGRIDTYPE.AIR]):
                if slot[TowerDefenseEnum.PLANTGRIDTYPE.AIR].instance.canBeCollection:
                    return slot[TowerDefenseEnum.PLANTGRIDTYPE.AIR]
    for characterKey: TowerDefenseCharacter in characterSlotDictionary.keys():
        if is_instance_valid(characterSlotDictionary[characterKey]):
            if checkInvincible && is_instance_valid(characterKey) && characterKey.instance.invincible:
                continue
            if _IsValidTarget(characterSlotDictionary[characterKey], camp, maskFlags, checkInvincible):
                return characterSlotDictionary[characterKey]
    for characterKey: TowerDefenseEnum.PLANTGRIDTYPE in slot.keys():
        if is_instance_valid(slot[characterKey]):
            if checkInvincible:
                var slotParent: TowerDefenseCharacter = FindSlotParent(slot[characterKey])
                if is_instance_valid(slotParent) && slotParent.instance.invincible:
                    continue
            if _IsValidTarget(slot[characterKey], camp, maskFlags, checkInvincible):
                return slot[characterKey]
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character):
            if checkInvincible:
                var slotParent: TowerDefenseCharacter = FindSlotParent(character)
                if is_instance_valid(slotParent) && slotParent.instance.invincible:
                    continue
            if _IsValidTarget(character, camp, maskFlags, checkInvincible):
                return character
    if isCataplut:
        if is_instance_valid(characterSurround):
            if characterSurround.instance.canBeCollection:
                if characterSurround.CanCollision(maskFlags):
                    if characterSurround.instance.maskFlags & maskFlags:
                        return characterSurround
    return null

func GetSlot(character: TowerDefenseCharacter) -> TowerDefenseCharacter:
    ClearEmpty()
    if !is_instance_valid(character):
        return null
    if characterSlotDictionary.has(character):
        if is_instance_valid(characterSlotDictionary[character]):
            var slotCharacter: TowerDefenseCharacter = characterSlotDictionary[character]
            if is_instance_valid(slotCharacter):
                return slotCharacter
        else:
            for characterCheck: TowerDefenseCharacter in characterList:
                if !is_instance_valid(characterCheck):
                    continue
                if characterCheck.config.plantGridType.has(character.config.plantGridOverrideType):
                    if slot.values().has(characterCheck):
                        continue
                    characterSlotDictionary[character] = characterCheck
                    break
            if characterSlotDictionary.has(character):
                if is_instance_valid(characterSlotDictionary[character]):
                    var slotCharacter: TowerDefenseCharacter = characterSlotDictionary[character]
                    return slotCharacter
    return null

func GetSurround() -> TowerDefenseCharacter:
    if is_instance_valid(characterSurround):
        return characterSurround
    return null

func FindSlotParent(character: TowerDefenseCharacter) -> TowerDefenseCharacter:
    for key in characterSlotDictionary.keys():
        if characterSlotDictionary[key] == character:
            return key
    return null

func HasPhysiqueType(flag: int) -> bool:
    ClearEmpty()
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character):
            if character.instance.physiqueTypeFlags & flag:
                return true
    return false

func HasWallnut() -> bool:
    return HasPhysiqueType(TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT)

func HasVase() -> bool:
    return HasPhysiqueType(TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.VASE)

func HasLight() -> bool:
    return HasPhysiqueType(TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.LIGHT)

func HasCoffee(camp: int = -2) -> bool:
    if camp == -2:
        return HasPhysiqueType(TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.COFFEE)
    ClearEmpty()
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character):
            if character.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.COFFEE:
                if character.camp == camp:
                    return true
    return false

func HasSpike() -> bool:
    return HasPhysiqueType(TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE)

func HasCharacter(characterName: String) -> bool:
    ClearEmpty()
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character):
            if character.config.name == characterName:
                return true
    return false

func GetCharacterByPhysiqueType(flag: int) -> TowerDefenseCharacter:
    ClearEmpty()
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character):
            if character.instance.physiqueTypeFlags & flag:
                return character
    return null

func GetVase() -> TowerDefenseCharacter:
    return GetCharacterByPhysiqueType(TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.VASE)

func GetSpike() -> TowerDefenseCharacter:
    return GetCharacterByPhysiqueType(TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE)

func IsWater() -> bool:
    return gridType.has(TowerDefenseEnum.PLANTGRIDTYPE.WATER)

func CanCraterCreate() -> bool:
    ClearEmpty()
    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        if !slot.has(type):
            continue
        if is_instance_valid(slot[type]):
            return false
    return true

func GetGroundHeight(percentage: float = 0.5) -> float:
    if !groundHeightCurve:
        return 0.0
    return groundHeightCurve.curve.sample(percentage)

func HasPlant() -> bool:
    ClearEmpty()
    for character: TowerDefenseCharacter in characterList:
        if is_instance_valid(character) && character is TowerDefensePlant:
            return true
    return false

func CanMowerMove() -> bool:
    if characterList.size() <= 0:
        return false
    for character: TowerDefenseCharacter in characterList:
        if !is_instance_valid(character):
            return false
        if !character.canMowerMove:
            return false
    return true

func CanMoveToCell(cell: TowerDefenseCellInstance, checkGridType: bool = true) -> bool:
    if cell.characterList.size() > 0:
        return false
    if checkGridType:
        if gridType != cell.gridType:
            return false
    return true

func MoveCharacterToCell(character: TowerDefenseCharacter, cell: TowerDefenseCellInstance) -> void :
    cell.CharacterPlant(character.packet, character, true)
    var tween = character.create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUART)
    tween.tween_property(character, ^"global_position", TowerDefenseManager.GetMapCellPlantPos(cell.gridPos), 0.5)
    tween.tween_property(character, ^"shadowComponent:saveShadowPosition", character.shadowComponent.saveShadowPosition + TowerDefenseManager.GetMapCellPlantPos(cell.gridPos) - character.global_position, 0.5)
    character.gridPos = cell.gridPos

func MoveToCell(cell: TowerDefenseCellInstance, jump: bool = false) -> void :
    cell.characterList = characterList.duplicate()
    cell.characterSlotDictionary = characterSlotDictionary.duplicate()
    cell.slot = slot.duplicate()
    if is_instance_valid(characterSurround):
        cell.characterSurround = characterSurround
    if is_instance_valid(characterLadder):
        cell.characterLadder = characterLadder

    for character: TowerDefenseCharacter in characterList:
        if character.destroy.is_connected(CharacterDestroy):
            character.destroy.disconnect(CharacterDestroy)
        character.destroy.connect(cell.CharacterDestroy)
        var tween = character.create_tween()
        tween.set_parallel(true)
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_QUART)
        tween.tween_property(character, ^"global_position", TowerDefenseManager.GetMapCellPlantPos(cell.gridPos), 0.5)
        tween.tween_property(character, ^"shadowComponent:saveShadowPosition", character.shadowComponent.saveShadowPosition + TowerDefenseManager.GetMapCellPlantPos(cell.gridPos) - character.global_position, 0.5)
        character.gridPos = cell.gridPos
        if jump:
            character.ySpeed = -200
    characterList.clear()
    characterSlotDictionary.clear()
    slot.clear()
    characterSurround = null
    characterLadder = null
    for type: TowerDefenseEnum.PLANTGRIDTYPE in gridType:
        slot[type] = null

@warning_ignore("unused_parameter")
func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    if !is_instance_valid(character):
        return
    if type == "Eat":
        if HasCharacter("PlantPotGarlic"):
            character.Garlic()
            var target: TowerDefenseCharacter = GetTarget(character.instance.maskFlags)
            if is_instance_valid(target):
                target.Hurt(10)
