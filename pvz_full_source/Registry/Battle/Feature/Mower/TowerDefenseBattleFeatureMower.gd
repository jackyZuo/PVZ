class_name TowerDefenseBattleFeatureMower extends TowerDefenseBattleFeature

const GRID_MAX_SIZE = 27

const TOWER_DEFENSE_MOWER_MANAGER = preload("uid://c0xrja6fjw4rr")

var mowerManager: TowerDefenseMowerManager

var mowerLine: Array[TowerDefenseMower]
var mowerHasRun: bool = false
var targetZombieLine: Array[TowerDefenseCharacter]

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    for y in range(GRID_MAX_SIZE):
        mowerLine.append(null)
        targetZombieLine.append(null)
    mowerManager = TOWER_DEFENSE_MOWER_MANAGER.instantiate()
    mowerManager.mowerFeature = self
    control.AddNode(mowerManager)

func MowerInit() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            CreateMower(line)

func CreateMower(line: int) -> TowerDefenseMower:
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return null
    if is_instance_valid(mowerLine[line]):
        return null
    var mowerPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(GameSaveManager.GetKeyValue("CurrentMower"))
    if mapFeature.LineHasType(line, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        mowerPacket = TowerDefenseManager.GetPacketConfig("MowerPoolCleaner")
    var pos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(Vector2i(0, line)) + Vector2(10, 0)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var mower = mowerPacket.Create(pos, Vector2i(0, line))
    mower.characterFilter = true
    mower.running.connect(MowerRun)
    mower.groundHeight = TowerDefenseManager.GetMapCell(Vector2(1, line)).GetGroundHeight(0.0)
    mower.z = mower.groundHeight
    characterNode.add_child(mower)
    mowerLine[line] = mower
    return mower

func MowerRun(mower: TowerDefenseMower) -> void :
    var line: int = mowerLine.find(mower)
    mowerLine[line] = null
    mowerHasRun = true

func IZM2Init() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            CreateTargetZombie(line)

func CreateTargetZombie(line: int) -> TowerDefenseCharacter:
    if is_instance_valid(targetZombieLine[line]):
        return null
    var brainPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieTarget")
    var pos: Vector2 = Vector2(TowerDefenseManager.GetMapGroundRight() + 40, TowerDefenseManager.GetMapCellPlantPos(Vector2i(0, line)).y)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var zombie = brainPacket.Create(pos, Vector2i(0, line))
    zombie.destroy.connect(TargetZombieDestroy)
    zombie.groundHeight = TowerDefenseManager.GetMapCell(Vector2(1, line)).GetGroundHeight(0.0)
    zombie.z = zombie.groundHeight
    characterNode.add_child(zombie)
    zombie.Rise()
    targetZombieLine[line] = zombie
    return zombie

func CheckIZM2Fail() -> void :
    if CommandManager.debug && CommandManager.debugNoLose:
        return
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            if is_instance_valid(targetZombieLine[line]):
                TowerDefenseManager.currentControl.GameFail(null)

@warning_ignore("unused_parameter")
func TargetZombieDestroy(character: TowerDefenseCharacter) -> void :
    if CommandManager.debug && CommandManager.debugNoLose:
        return
    var levelControl: TowerDefenseInGameLevelControl = TowerDefenseInGameLevelControl.instance
    if is_instance_valid(levelControl) && levelControl.awardCreate:
        return
    TowerDefenseManager.currentControl.GameFail(null)

func GameFail() -> void :
    for mower: TowerDefenseMower in mowerLine:
        if is_instance_valid(mower):
            mower.process_mode = Node.PROCESS_MODE_DISABLED

func SyncSerialize() -> Dictionary:
    var mowers: Array = []
    var serialized_lines: Dictionary = {}
    for mower in mowerLine:
        if is_instance_valid(mower):
            mowers.append({
                "line": mower.gridPos.y, 
                "alive": !mower.IsDie() if mower.has_method("IsDie") else true, 
                "running": mower.run
            })
            serialized_lines[mower.gridPos.y] = true
    var running_mowers: Array = (Engine.get_main_loop() as SceneTree).get_nodes_in_group("Mower")
    for mower in running_mowers:
        if mower is TowerDefenseMower and is_instance_valid(mower) and !mower.IsDie() and !serialized_lines.has(mower.gridPos.y):
            mowers.append({
                "line": mower.gridPos.y, 
                "alive": true, 
                "running": mower.run
            })
    return {"mowers": mowers}

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("mowers"):
        var mowers_data: Array = _data["mowers"]
        for mower_data in mowers_data:
            var line: int = mower_data.get("line", 0)
            var alive: bool = mower_data.get("alive", true)
            var running: bool = mower_data.get("running", false)
            if !alive:
                var found: bool = false
                for mower in mowerLine:
                    if is_instance_valid(mower) and mower.gridPos.y == line:
                        mower.Destroy()
                        found = true
                        break
                if !found:
                    for mower in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("Mower"):
                        if mower is TowerDefenseMower and is_instance_valid(mower) and mower.gridPos.y == line:
                            mower.Destroy()
                            break
            elif running:
                var found: bool = false
                for mower in mowerLine:
                    if is_instance_valid(mower) and mower.gridPos.y == line and !mower.run:
                        mower.Run()
                        mower.run = true
                        found = true
                        break
                if !found:
                    for mower in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("Mower"):
                        if mower is TowerDefenseMower and is_instance_valid(mower) and mower.gridPos.y == line and !mower.run:
                            mower.Run()
                            mower.run = true
                            break

func SaveFeature() -> Dictionary:
    return {
        "mowerHasRun": mowerHasRun, 
    }

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    mowerHasRun = _data.get("mowerHasRun", false)
