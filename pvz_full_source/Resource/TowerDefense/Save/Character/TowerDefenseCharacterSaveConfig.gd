class_name TowerDefenseCharacterSaveConfig extends Resource

@export var nodeName: StringName
@export var packetName: String
@export var pos: Vector2
@export var gridPos: Vector2i
@export var height: float

@export var characterNodeSave: TowerDefenseNodeSaveConfig

@export var instanceSave: Dictionary = {}
@export var buffSave: Array[Dictionary] = []
@export var currentArmor: Array[String] = []
@export var currentCustom: Array[String] = []
@export var timeScale: float = 1.0
@export var timeScaleInit: float = 1.0
@export var timeScaleSave: float = 1.0

@export var stateChartSave: Dictionary = {}
@export var spriteSave: Dictionary = {}
@export var componentSaveList: Array[Dictionary] = []
@export var characterFlags: Dictionary = {}
@export var zombieExtraSave: Dictionary = {}
@export var scaleX: float = 1.0
@export var scaleY: float = 1.0
@export var transformPointScaleX: float = 1.0
@export var transformPointScaleY: float = 1.0
@export var overrideSave: Dictionary = {}
@export var variantSave: Dictionary = {}

@export var z: float = 0.0
@export var ySpeed: float = 0.0
@export var isGround: bool = true
@export var cellPercentage: float = 0.5
@export var cost: float = 0.0

var owner: TowerDefenseLevelSaveConfig

func SaveCharacter(character: TowerDefenseCharacter) -> void :
    owner = null
    nodeName = character.name.validate_node_name()
    packetName = character.config.name
    print("[Save] 保存角色: %s (%s) pos=(%.1f, %.1f) gridPos=(%d, %d)" % [nodeName, packetName, character.global_position.x, character.global_position.y, character.gridPos.x, character.gridPos.y])
    pos = character.global_position
    gridPos = character.gridPos
    height = character.groundHeight
    instanceSave = character.instance.ExportSave()
    buffSave = character.buff.ExportSave()
    currentArmor.clear()
    for armorInstance: TowerDefenseArmorInstance in character.instance.armorList:
        if !armorInstance.isRemove:
            currentArmor.append(armorInstance.config.armorName)
    currentCustom = character.currentCustom
    timeScale = character.timeScale
    timeScaleInit = character.timeScaleInit
    timeScaleSave = character.timeScaleSave
    scaleX = character.scale.x
    scaleY = character.scale.y
    if is_instance_valid(character.transformPoint):
        transformPointScaleX = character.transformPoint.scale.x
        transformPointScaleY = character.transformPoint.scale.y
    if is_instance_valid(character.packet) and is_instance_valid(character.packet.override):
        overrideSave = character.packet.override.Export()
    else:
        overrideSave = {}
    var stateChart: StateChart = character.get_node_or_null("StateChart")
    if stateChart and is_instance_valid(stateChart._state):
        var rootSavedState: SavedState = SavedState.new()
        stateChart._state._state_save(rootSavedState)
        stateChartSave = {
            "child_states": rootSavedState.child_states, 
            "pending_transition_name": rootSavedState.pending_transition_name, 
            "pending_transition_remaining_delay": rootSavedState.pending_transition_remaining_delay, 
            "pending_transition_initial_delay": rootSavedState.pending_transition_initial_delay, 
        }
    if is_instance_valid(character.sprite):
        spriteSave = character.sprite.ExportSpriteSave()
    componentSaveList.clear()
    if is_instance_valid(character.componentManager):
        for component: ComponentBase in character.componentManager.componentList:
            if !component.alive:
                continue
            var componentData: Dictionary = component.ExportComponentSave()
            if componentData.size() > 0:
                componentData["_componentName"] = component.name
                componentSaveList.append(componentData)
    characterFlags = {
        "componentAlive": character.componentAlive, 
        "componentRunning": character.componentRunning, 
        "invisible": character.invisible, 
        "inWater": character.inWater, 
        "iceSpeedDown": character.iceSpeedDown, 
        "isRise": character.isRise, 
        "isShovel": character.isShovel, 
        "isSmash": character.isSmash, 
        "isExplode": character.isExplode, 
        "isChomp": character.isChomp, 
        "isUnlimitedFire": character.isUnlimitedFire, 
        "useIdleAnimeReset": character.useIdleAnimeReset, 
        "nearDie": character.nearDie, 
        "canMowerMove": character.canMowerMove, 
        "die": character.die, 
        "inGame": character.inGame, 
        "characterFilter": character.characterFilter, 
    }
    z = character.z
    ySpeed = character.ySpeed
    isGround = character.isGround
    cellPercentage = character.cellPercentage
    cost = character.cost
    variantSave = character.ExportVariantSave()
    if character is TowerDefenseZombie:
        var zombie: TowerDefenseZombie = character as TowerDefenseZombie
        zombieExtraSave = {
            "isPause": zombie.isPause, 
            "isGarlic": zombie.isGarlic, 
            "isChangeLine": zombie.isChangeLine, 
            "inSwimPlay": zombie.inSwimPlay, 
            "inGround": zombie.inGround, 
            "startAttack": zombie.startAttack, 
            "sizeUpNum": zombie.sizeUpNum, 
            "isCarry": zombie.isCarry, 
            "spritePause": zombie.spritePause, 
            "walkSpeedScale": zombie.walkSpeedScale, 
        }
        print("[Save] 角色僵尸额外数据已保存: isPause=%s, isGarlic=%s, inGround=%s" % [zombie.isPause, zombie.isGarlic, zombie.inGround])
    print("[Save] 角色保存完成: %s 组件数=%d 状态机=%s 动画=%s 变体=%s" % [nodeName, componentSaveList.size(), "有" if stateChartSave.size() > 0 else "无", "有" if spriteSave.size() > 0 else "无", "有" if variantSave.size() > 0 else "无"])

func LoadCharacter() -> TowerDefenseCharacter:
    print("[Load] 加载角色: %s (%s) pos=(%.1f, %.1f) gridPos=(%d, %d)" % [nodeName, packetName, pos.x, pos.y, gridPos.x, gridPos.y])
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetName)
    var character: TowerDefenseCharacter = packetConfig.Create(pos, gridPos, height)
    character.groundHeight = height
    characterNode.add_child(character)
    character.currentArmor = currentArmor
    character.currentCustom = currentCustom
    character.packet = packetConfig
    if overrideSave.size() > 0:
        var override: TowerDefensePacketOverride = TowerDefensePacketOverride.new()
        override.Init(overrideSave)
        packetConfig.override = override
    character.RestoreFromSave(self)
    character.scale = Vector2(scaleX, scaleY)
    if is_instance_valid(character.transformPoint):
        character.transformPoint.scale = Vector2(transformPointScaleX, transformPointScaleY)
    if is_instance_valid(character.shadowComponent):
        character.shadowComponent.Init()
    var waterInteractionComponent: WaterInteractionComponent = character.componentManager.GetComponentFromType("WaterInteractionComponent") if is_instance_valid(character.componentManager) else null
    if is_instance_valid(waterInteractionComponent):
        waterInteractionComponent.saveTransformPointScaleY = character.transformPoint.scale.y
        waterInteractionComponent.saveSpriteGroupScaleY = character.spriteGroup.scale.y
    character.isGround = isGround
    character.z = z
    character.ySpeed = ySpeed
    character.cellPercentage = cellPercentage
    character.cost = cost
    character.componentAlive = characterFlags.get("componentAlive", true)
    character.componentRunning = characterFlags.get("componentRunning", false)
    character.invisible = characterFlags.get("invisible", false)
    character.iceSpeedDown = characterFlags.get("iceSpeedDown", false)
    character.isRise = characterFlags.get("isRise", false)
    character.isShovel = characterFlags.get("isShovel", false)
    character.isSmash = characterFlags.get("isSmash", false)
    character.isExplode = characterFlags.get("isExplode", false)
    character.isChomp = characterFlags.get("isChomp", false)
    character.isUnlimitedFire = characterFlags.get("isUnlimitedFire", false)
    character.useIdleAnimeReset = characterFlags.get("useIdleAnimeReset", true)
    character.nearDie = characterFlags.get("nearDie", false)
    character.canMowerMove = characterFlags.get("canMowerMove", false)
    character.die = characterFlags.get("die", false)
    character.inGame = characterFlags.get("inGame", true)
    character.characterFilter = characterFlags.get("characterFilter", false)
    for componentData: Dictionary in componentSaveList:
        var componentName: String = componentData.get("_componentName", "")
        if componentName == "":
            continue
        var component: ComponentBase = character.componentManager.GetComponentFromName(componentName)
        if is_instance_valid(component):
            component.ImportComponentSave(componentData, owner)
    character.inWater = characterFlags.get("inWater", false)
    if character is TowerDefenseZombie and zombieExtraSave.size() > 0:
        var zombie: TowerDefenseZombie = character as TowerDefenseZombie
        zombie.isGarlic = zombieExtraSave.get("isGarlic", false)
        zombie.isChangeLine = zombieExtraSave.get("isChangeLine", false)
        zombie.inSwimPlay = zombieExtraSave.get("inSwimPlay", false)
        zombie.inGround = zombieExtraSave.get("inGround", false)
        zombie.startAttack = zombieExtraSave.get("startAttack", false)
        zombie.sizeUpNum = zombieExtraSave.get("sizeUpNum", 2)
        zombie.isCarry = zombieExtraSave.get("isCarry", false)
        zombie.walkSpeedScale = zombieExtraSave.get("walkSpeedScale", 1.0)
    var stateChart: StateChart = character.get_node_or_null("StateChart")
    if stateChart and is_instance_valid(stateChart._state) and stateChartSave.size() > 0:
        var rootSavedState: SavedState = SavedState.new()
        rootSavedState.child_states = stateChartSave.get("child_states", {})
        rootSavedState.pending_transition_name = stateChartSave.get("pending_transition_name", "")
        rootSavedState.pending_transition_remaining_delay = stateChartSave.get("pending_transition_remaining_delay", 0.0)
        rootSavedState.pending_transition_initial_delay = stateChartSave.get("pending_transition_initial_delay", 0.0)
        stateChart._state._state_restore(rootSavedState)
        character.timeScaleInit = timeScaleInit
        character.timeScaleSave = timeScaleSave
        if character is TowerDefensePlant:
            character.sprite.timeScale = timeScale
    if is_instance_valid(character.sprite) and spriteSave.size() > 0:
        character.sprite.ImportSpriteSave(spriteSave)
    if character is TowerDefenseZombie and zombieExtraSave.size() > 0:
        var zombie: TowerDefenseZombie = character as TowerDefenseZombie
        zombie.spritePause = zombieExtraSave.get("spritePause", false)
        zombie.isPause = zombieExtraSave.get("isPause", false)
    if variantSave.size() > 0:
        character.ImportVariantSave(variantSave)
    character.componentRunning = false
    print("[Load] 角色加载完成: %s 组件数=%d 状态机=%s 动画=%s 变体=%s" % [nodeName, componentSaveList.size(), "已恢复" if stateChartSave.size() > 0 else "无", "已恢复" if spriteSave.size() > 0 else "无", "已恢复" if variantSave.size() > 0 else "无"])
    return character
