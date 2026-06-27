class_name TowerDefenseBattleFeatureLookStar extends TowerDefenseBattleFeature

var config: TowerDefenseLevelLookStarManagerConfig
var characterLayer: CanvasLayer
var checkDictionary: Dictionary = {}
var isfinish: bool = false



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelLookStarManagerConfig.new()
    config.Init(data)
    characterLayer = CanvasLayer.new()
    characterLayer.follow_viewport_enabled = true
    characterLayer.layer = 2
    var lookStarNode: Node2D = Node2D.new()
    control.AddNode(lookStarNode, 2)
    lookStarNode.add_child(characterLayer)

func GameInit() -> void :
    for check: TowerDefenseLevelLookStarCheckConfig in config.checkList:
        if !checkDictionary.has(check):
            checkDictionary[check] = null
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(check.gridPos)
        if !is_instance_valid(checkDictionary[check]):
            var sprite = TowerDefenseManager.GetCharacterSprite(check.packetName)
            characterLayer.add_child(sprite)
            sprite.global_position = TowerDefenseManager.GetMapCellPlantPos(check.gridPos)
            sprite.meshColor.a = 0.5
            sprite.pause = true
            checkDictionary[check] = sprite
            if is_instance_valid(cell):
                sprite.global_position.y -= cell.GetGroundHeight()
    FreshGround()

func GameInitFromProgress() -> void :
    for check: TowerDefenseLevelLookStarCheckConfig in config.checkList:
        if !checkDictionary.has(check):
            checkDictionary[check] = null

func Process(_delta: float) -> void :
    if !config.open:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if isfinish:
        return
    if Engine.get_physics_frames() % 30 == 0:
        FreshGround()



func FreshGround() -> void :
    var finishFlag: bool = true
    for check: TowerDefenseLevelLookStarCheckConfig in config.checkList:
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(check.gridPos)
        if is_instance_valid(cell):
            var hasChar: bool = cell.HasCharacter(check.packetName)
            if is_instance_valid(checkDictionary[check]):
                checkDictionary[check].visible = !hasChar
            if !hasChar:
                finishFlag = false
    if finishFlag:
        GetProcess().Finish()
        isfinish = true

func IsOpen() -> bool:
    return config.open

func OnWaveReachFinal(waveFeature: TowerDefenseBattleFeatureWave) -> bool:
    if !config.open || isfinish:
        return false
    waveFeature.waveFinal = false
    waveFeature.currentWave -= waveFeature.config.flagWaveInterval
    waveFeature.spawnOver = false
    waveFeature.nextWaveTime = waveFeature.config.spawnColStart
    return true

func SaveFeature() -> Dictionary:
    return {
        "isfinish": isfinish, 
    }

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    isfinish = _data.get("isfinish", false)
    if isfinish:
        return
    for check: TowerDefenseLevelLookStarCheckConfig in config.checkList:
        if !checkDictionary.has(check):
            checkDictionary[check] = null
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(check.gridPos)
        if is_instance_valid(cell) and cell.HasCharacter(check.packetName):
            continue
        if !is_instance_valid(checkDictionary[check]):
            var sprite = TowerDefenseManager.GetCharacterSprite(check.packetName)
            characterLayer.add_child(sprite)
            sprite.global_position = TowerDefenseManager.GetMapCellPlantPos(check.gridPos)
            sprite.meshColor.a = 0.5
            sprite.pause = true
            checkDictionary[check] = sprite
            if is_instance_valid(cell):
                sprite.global_position.y -= cell.GetGroundHeight()
    FreshGround()
