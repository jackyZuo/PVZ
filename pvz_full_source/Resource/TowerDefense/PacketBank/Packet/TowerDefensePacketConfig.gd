@tool
class_name TowerDefensePacketConfig extends Resource

@export var saveKey: String = ""
@export var unlockCheckList: Array[UnlockConditionBaseConfig]
@export var name: String
@export var describe: String
@export var plantfood: String
@export var handbookDescribe: String
@export var handbookStory: String
@export var packetFlip: bool = false
@export var packetAnimeClip: String = "Idle"
@export var handbookPacketAnimeOffset: Vector2 = Vector2.ZERO
@export var packetAnimeOffset: Vector2 = Vector2.ZERO
@export var packetAnimeScale: Vector2 = Vector2.ZERO
@export var characterConfig: TowerDefenseCharacterConfig:
    set(_characterConfig):
        characterConfig = _characterConfig
        notify_property_list_changed()
@export var type: TowerDefenseEnum.PACKET_TYPE = TowerDefenseEnum.PACKET_TYPE.WHITE
@export var canChangeCost: bool = true
@export_category("Spawn")
@export_enum("Noone", "Rise", "FlyDown") var spawnMethod: String = "Rise"
@export_category("Event")
@export var eventPress: Array[TowerDefensePacketEventBase]
@export var eventPlant: Array[TowerDefensePacketEventBase]
@export_category("Override")
@export var override: TowerDefensePacketOverride
@export var overrideHypnoses: bool = false
@export var overrideCostRise: int = -1
@export var overrideCost: int = -1
@export var overridePacketCooldown: float = -1
@export var overrideStartingCooldown: float = -1
@export_storage var overrideWeight: int = -1
@export_storage var overrideWavePointCost: int = -1
@export_category("Other")
@export_storage var initArmor: Array[String]
@export_storage var plantUseCell: bool = true
@export var izmPlantAllCell: bool = false
@export var izmPlantLeft: bool = false

var changeCostList: Array[TowerDefensePacketChangeCost] = []
var coldDownDecreaseDictionary: Dictionary = {}

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []

    if characterConfig:
        if characterConfig.armorData:
            properties.append(
                {
                    "name": "Armor", 
                    "type": TYPE_ARRAY, 
                    "hint": PROPERTY_HINT_ENUM, 
                    "hint_string": "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, ",".join(characterConfig.armorData.armorDictionary.keys())], 
                }
            )
        properties.append(
            {
                "name": "Cell/plantUseCell", 
                "type": TYPE_BOOL
            }
        )
        if characterConfig is TowerDefenseZombieConfig:
            properties.append(
                {
                    "name": "Override/overrideWeight", 
                    "type": TYPE_INT
                }
            )
            properties.append(
                {
                    "name": "Override/overrideWavePointCost", 
                    "type": TYPE_INT
                }
            )
    return properties

func _set(property: StringName, value: Variant) -> bool:
    match property:
        "Armor":
            initArmor.clear()
            for item in value:
                initArmor.append(str(item))
            return true
        "Override/overrideWeight":
            overrideWeight = value
            return true
        "Override/overrideWavePointCost":
            overrideWavePointCost = value
            return true
        "Cell/plantUseCell":
            plantUseCell = value
            return true
    return false

func _get(property: StringName) -> Variant:
    match property:
        "Armor":
            return initArmor
        "Override/overrideWeight":
            return overrideWeight
        "Override/overrideWavePointCost":
            return overrideWavePointCost
        "Cell/plantUseCell":
            return plantUseCell
    return null

func _property_can_revert(property: StringName) -> bool:
    match property:
        "Armor":
            return true
        "Override/overrideWeight":
            return true
        "Override/overrideWavePointCost":
            return true
        "Cell/plantUseCell":
            return true
    return false

func _property_get_revert(property: StringName) -> Variant:
    match property:
        "Armor":
            return Array([], TYPE_STRING, "", null)
        "Override/overrideWeight":
            return -1
        "Override/overrideWavePointCost":
            return -1
        "Cell/plantUseCell":
            return true
    return null

func GetType() -> TowerDefenseEnum.PACKET_TYPE:
    if is_instance_valid(override):
        if override.type != TowerDefenseEnum.PACKET_TYPE.NOONE:
            return override.type
    return type

func GetCostRise() -> int:
    if is_instance_valid(override):
        if override.costRise != -1:
            return override.costRise
    if overrideCostRise != -1:
        return overrideCostRise
    return characterConfig.costRise

func GetCostMultiple() -> float:
    if is_instance_valid(override):
        if override.costMultiple != -1:
            return override.costMultiple
    return characterConfig.costMultiple

func GetCost() -> int:
    var cost: int = characterConfig.cost
    if overrideCost != -1:
        cost = overrideCost
    if is_instance_valid(override):
        if override.cost != -1:
            cost = override.cost
    if characterConfig.costNight != -1 && TowerDefenseManager.GetMapIsNight():
        cost = characterConfig.costNight
    var costTemp: int = cost
    for changeCost: TowerDefensePacketChangeCost in changeCostList:
        costTemp = changeCost.Execute(costTemp, self)
        if changeCost.skip:
            break
    for changeCost: TowerDefensePacketChangeCost in TowerDefenseManager.GetChangeCostList():
        costTemp = changeCost.Execute(costTemp, self)
        if changeCost.skip:
            break
    if cost >= 0:
        if costTemp < 0:
            cost = 0
        else:
            cost = costTemp
    else:
        cost = costTemp
    return cost

func GetPacketCooldown() -> float:
    var percentage: float = 1.0
    if TowerDefenseManager.IsUnlimitedFire():
        percentage *= 2.0 / 3.0
    for key: String in coldDownDecreaseDictionary.keys():
        var data: Dictionary = coldDownDecreaseDictionary[key]
        for characterCheckId in data["ControlCharacterList"].size():
            for characterId in data["ControlCharacterList"].size():
                if !is_instance_valid(data["ControlCharacterList"][characterId]):
                    data["ControlCharacterList"].remove_at(characterId)
                    break
        if data["ControlCharacterList"].size() <= 0:
            coldDownDecreaseDictionary.erase(key)

    for key: String in coldDownDecreaseDictionary.keys():
        var data: Dictionary = coldDownDecreaseDictionary[key]
        if data["ControlCharacterList"].size() > 0:
            percentage -= data["Percentage"]

    if GetType() == TowerDefenseEnum.PACKET_TYPE.GOLD:
        var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
        if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.config):
            if mapFeature.config.isHeaven:
                percentage *= 0.5

    if percentage < 0.0:
        percentage = 0.0

    if is_instance_valid(override):
        if override.packetCooldown != -1:
            return override.packetCooldown * percentage
    if overridePacketCooldown != -1:
        return overridePacketCooldown * percentage
    return characterConfig.packetCooldown * percentage

func GetStartingCooldown() -> float:
    var percentage: float = 1.0
    if TowerDefenseManager.IsUnlimitedFire():
        percentage *= 2.0 / 3.0
    if is_instance_valid(override):
        if override.startingCooldown != -1:
            return override.startingCooldown * percentage
    if overrideStartingCooldown != -1:
        return overrideStartingCooldown * percentage
    return characterConfig.startingCooldown * percentage

func GetWeight() -> int:
    if is_instance_valid(override):
        if override.weight != -1:
            return override.weight
    if overrideWeight != -1:
        return overrideWeight
    return characterConfig.weight

func GetWavePointCost() -> int:
    if is_instance_valid(override):
        if override.wavePointCost != -1:
            return override.wavePointCost
    if overrideWavePointCost != -1:
        return overrideWavePointCost
    return characterConfig.wavePointCost

func GetPlantCover() -> Array[String]:
    if is_instance_valid(override):
        if override.plantCover.size() > 0:
            return override.plantCover
    return characterConfig.plantCover

func GetCoverCanDirectPlant() -> bool:
    if is_instance_valid(override):
        return override.coverCanDirectPlant
    return false

func GetHypnoses() -> bool:
    if is_instance_valid(override):
        if override.hypnoses:
            return override.hypnoses
    return overrideHypnoses

func IsLimitGridNum() -> bool:
    if is_instance_valid(override):
        return override.islimitGridNum
    return true

func ExecuteEventPress(packet: TowerDefenseInGamePacketShow) -> void :
    var eventList: Array[TowerDefensePacketEventBase] = eventPress
    if is_instance_valid(override):
        if override.eventPress.size() > 0:
            eventList = override.eventPress
    for event: TowerDefensePacketEventBase in eventList:
        event.Execute(packet)

func ExecuteEventPlant(packet: TowerDefenseInGamePacketShow) -> void :
    var eventList: Array[TowerDefensePacketEventBase] = eventPlant
    if is_instance_valid(override):
        if override.eventPlant.size() > 0:
            eventList = override.eventPlant
    for event: TowerDefensePacketEventBase in eventList:
        event.Execute(packet)

func Plant(gridPos: Vector2i, playAudio: bool = true, noLimit: bool = false) -> TowerDefenseCharacter:
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        if is_instance_valid(cell):
            if !(characterConfig is TowerDefenseVaseConfig) && cell.HasVase():
                var vase = cell.GetVase() as TowerDefenseVase
                vase.packetConfig = self.duplicate(true)
                return null
    if !(characterConfig is TowerDefenseZombieConfig) && !is_instance_valid(cell):
        return null
    if !(characterConfig is TowerDefenseZombieConfig) && !cell.CanPacketPlant(self, noLimit):
        return null
    var charcaterName: String = characterConfig.name
    var chacraterScene: PackedScene = TowerDefenseManager.GetChacraterScene(charcaterName)
    var character: TowerDefenseCharacter = chacraterScene.instantiate()
    if characterConfig.armorData:
        if initArmor.size() > 0:
            for armor in initArmor:
                character.currentArmor.append(str(armor))
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var plantPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(gridPos)
    character.global_position = plantPos / TowerDefenseManager.GetMapFeature().mapControl.global_scale.y
    character.gridPos = gridPos
    character.cost = characterConfig.cost
    character.packet = self
    if packetFlip:
        character.scale.x = - character.scale.x
    if is_instance_valid(cell):
        character.groundHeight = cell.GetGroundHeight(0.5)
    character.z = character.groundHeight
    characterNode.add_child(character)
    if GetHypnoses():
        character.Hypnoses()
    if is_instance_valid(override):
        if is_instance_valid(override.characterOverride):
            override.characterOverride.ExecuteCharacter(character)
    if Global.isEditor && SceneManager.currentScene == "LevelEditorStage":
        character.inGame = false
        character.process_mode = Node.PROCESS_MODE_DISABLED
        character.sprite.process_mode = Node.PROCESS_MODE_ALWAYS
        character.sprite.SetAnimation(packetAnimeClip, true)
    var saveIndex: int = -1
    var maxX: int = -1
    for nodeId in characterNode.get_child_count():
        var node: Node = characterNode.get_child(nodeId)
        if node is TowerDefenseCharacter:
            if node == character:
                continue
            if node.itemLayer != character.itemLayer:
                continue
            if node.gridPos.y != character.gridPos.y:
                continue
            if node.gridPos.x > maxX && node.gridPos.x <= character.gridPos.x:
                maxX = node.gridPos.x
                saveIndex = nodeId
    if saveIndex != -1:
        characterNode.move_child(character, saveIndex)

    if overrideCost != -1:
        character.cost = characterConfig.cost
    var plantedEffect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(load("uid://du8ukldfc7fh7"), gridPos)
    characterNode.add_child(plantedEffect)
    plantedEffect.global_position = character.transformPoint.global_position
    if plantUseCell && !(characterConfig is TowerDefenseZombieConfig):
        cell.CharacterPlant(self, character, noLimit)
        if characterConfig is TowerDefensePlantConfig:
            if characterConfig.extendCoverDictionary.is_empty():
                for offset in characterConfig.extendGrid:
                    var extendCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + offset)
                    extendCell.CharacterPlant(self, character, noLimit)

    if is_instance_valid(TowerDefenseManager.currentControl) && TowerDefenseManager.currentControl.isGameRunning:
        if !Global.isEditor || SceneManager.currentScene != "LevelEditorStage":
            if characterConfig is TowerDefenseZombieConfig:
                if character is TowerDefenseZombie:
                    IsZombieWalk(character)

    if playAudio:
        if is_instance_valid(cell) && cell.gridType.has(TowerDefenseEnum.PLANTGRIDTYPE.WATER):
            AudioManager.AudioPlay("PlantWater", AudioManagerEnum.TYPE.SFX)
        else:
            AudioManager.AudioPlay("Plant", AudioManagerEnum.TYPE.SFX)
    if is_instance_valid(TowerDefenseInGameLevelControl.instance):
        TowerDefenseInGameLevelControl.instance.hasSpawn = true
    return character

func HasSpawnLimit() -> bool:
    if characterConfig is TowerDefenseZombieConfig:
        if characterConfig.spawnLineNeed.size() > 0:
            return true
        if characterConfig.excludeLineGridType.size() > 0:
            return true
    return false

func CanSpawn(line: int) -> bool:
    var flag: bool = true
    if characterConfig is TowerDefenseZombieConfig:
        for gridType: TowerDefenseEnum.PLANTGRIDTYPE in characterConfig.spawnLineNeed:
            if !TowerDefenseManager.MapLineHasType(line, gridType):
                flag = false
                break
        for gridType: TowerDefenseEnum.PLANTGRIDTYPE in characterConfig.excludeLineGridType:
            if TowerDefenseManager.MapLineHasType(line, gridType):
                flag = false
                break
    return flag

func Spawn(line: int, offsetX: float = 0.0, isIdle: bool = false) -> TowerDefenseCharacter:
    var charcaterName: String = characterConfig.name
    var chacraterScene: PackedScene = TowerDefenseManager.GetChacraterScene(charcaterName)
    var character: TowerDefenseCharacter = chacraterScene.instantiate()
    if characterConfig.armorData:
        if initArmor.size() > 0:
            for armor in initArmor:
                character.currentArmor.append(str(armor))
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    var spawnPos: Vector2 = Vector2(mapFeature.config.edge.z + 40 + offsetX, TowerDefenseManager.GetMapLineY(line))
    character.global_position = spawnPos
    character.gridPos = Vector2i(-1, line)
    character.packet = self
    characterNode.add_child(character)
    if !isIdle:
        match spawnMethod:
            "Rise":
                character.Rise()
            "FlyDown":
                character.isGround = false
                character.z = 900
        character.Spawn()
    if !isIdle:
        if characterConfig is TowerDefenseZombieConfig:
            if character is TowerDefenseZombie:
                IsZombieWalk(character)
    RandomAnime(character)
    if is_instance_valid(TowerDefenseInGameLevelControl.instance):
        TowerDefenseInGameLevelControl.instance.hasSpawn = true
    return character

func Create(pos: Vector2, gridPos: Vector2, height: float = 0.0) -> TowerDefenseCharacter:
    var charcaterName: String = characterConfig.name
    var chacraterScene: PackedScene = TowerDefenseManager.GetChacraterScene(charcaterName)
    var character: TowerDefenseCharacter = chacraterScene.instantiate()
    if characterConfig.armorData:
        if initArmor.size() > 0:
            for armor in initArmor:
                character.currentArmor.append(str(armor))
    character.z = height
    character.global_position = pos
    character.gridPos = gridPos
    character.packet = self
    if is_instance_valid(TowerDefenseInGameLevelControl.instance):
        TowerDefenseInGameLevelControl.instance.hasSpawn = true
    return character

func RandomAnime(character: TowerDefenseCharacter):
    if is_instance_valid(character):
        character.sprite.frameIndex += randi_range(0, 20)

func IsZombieWalk(character: TowerDefenseCharacter):
    await character.get_tree().physics_frame
    if !character.die && !character.nearDie && !character.isRise:
        character.Walk.call_deferred()

func Unlock() -> bool:
    if CommandManager.debugPacketOpenAll:
        return true
    var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue(saveKey)
    if !packetValue.get_or_add("Unlock", false):
        if unlockCheckList.size() <= 0:
            return false
        else:
            for unlockCheck: UnlockConditionBaseConfig in unlockCheckList:
                if !unlockCheck.Check():
                    return false
            packetValue["Unlock"] = true
            GameSaveManager.SetTowerDefensePacketValue(saveKey, packetValue)
            GameSaveManager.Save()
    return true

func ColdDownDecreaseAdd(controlCharacter: TowerDefenseCharacter, key: String, percentage: float) -> void :
    if !coldDownDecreaseDictionary.has(key):
        coldDownDecreaseDictionary[key] = {
            "ControlCharacterList" = [], 
            "Percentage" = percentage
        }
    if !coldDownDecreaseDictionary[key]["ControlCharacterList"].has(controlCharacter):
        controlCharacter.destroy.connect(ColdDownDecreaseDelete.bind(key))
        coldDownDecreaseDictionary[key]["ControlCharacterList"].append(controlCharacter)

func ColdDownDecreaseDelete(controlCharacter: TowerDefenseCharacter, key: String) -> void :
    if !coldDownDecreaseDictionary.has(key):
        return
    coldDownDecreaseDictionary[key]["ControlCharacterList"].erase(controlCharacter)
    if coldDownDecreaseDictionary[key]["ControlCharacterList"].size() <= 0:
        coldDownDecreaseDictionary.erase(key)

func ChangeCostAdd(changeCost: TowerDefensePacketChangeCost) -> bool:
    if changeCost.key != "":
        for existing: TowerDefensePacketChangeCost in changeCostList:
            if existing.key == changeCost.key:
                return false
    changeCostList.append(changeCost)
    if changeCost.lockCost:
        canChangeCost = false
    return true

func ChangeCostRemove(changeCost: TowerDefensePacketChangeCost) -> bool:
    var idx: int = changeCostList.find(changeCost)
    if idx == -1:
        return false
    changeCostList.remove_at(idx)
    if changeCost.lockCost:
        var hasLock: bool = false
        for existing: TowerDefensePacketChangeCost in changeCostList:
            if existing.lockCost:
                hasLock = true
                break
        if !hasLock:
            canChangeCost = true
    return true
