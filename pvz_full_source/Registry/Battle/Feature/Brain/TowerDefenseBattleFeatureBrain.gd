class_name TowerDefenseBattleFeatureBrain extends TowerDefenseBattleFeature

const GRID_MAX_SIZE = 27

var brainLine: Array[TowerDefenseItem]



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    for y in range(GRID_MAX_SIZE):
        brainLine.append(null)

func GameReady() -> void :
    pass

func SyncSerialize() -> Dictionary:
    var brain_lines: Array = []
    for line in range(GRID_MAX_SIZE):
        if is_instance_valid(brainLine[line]) and !brainLine[line].isDestroy:
            brain_lines.append(line)
    return {"brain_lines": brain_lines}

func SyncDeserialize(_data: Dictionary) -> void :
    if !_data.has("brain_lines"):
        return
    var alive_lines: Array = _data["brain_lines"]
    for line in range(GRID_MAX_SIZE):
        if is_instance_valid(brainLine[line]) and !brainLine[line].isDestroy:
            if !(line in alive_lines):
                if is_instance_valid(brainLine[line].destroyComponent):
                    brainLine[line].destroyComponent.is_remote_destroy = true
                brainLine[line].Destroy()
                brainLine[line] = null



func BrainInit() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    for line in range(1, mapFeature.config.gridNum.y + 1):
        if mapFeature.lineUse[line]:
            CreateBrain(line)

func CreateBrain(line: int) -> TowerDefenseItem:
    if is_instance_valid(brainLine[line]):
        return null
    var brainPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ItemBrain")
    var pos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(Vector2i(0, line)) + Vector2(10, 0)
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var brain = brainPacket.Create(pos, Vector2i(0, line))
    brain.characterFilter = true
    brain.brainDestroy.connect(BrainDestroy)
    brain.groundHeight = TowerDefenseManager.GetMapCell(Vector2(1, line)).GetGroundHeight(0.0)
    brain.z = brain.groundHeight
    characterNode.add_child(brain)
    brainLine[line] = brain
    if Global.isMultiplayerMode and is_instance_valid(control):
        var sync_id: int = control._get_next_sync_id()
        control._register_sync_character(sync_id, brain)
    return brain

func BrainDestroy() -> void :
    var currentControl = TowerDefenseManager.currentControl
    var progessFeature: TowerDefenseBattleFeatureProgess = currentControl.GetFeature("Progess")
    progessFeature.IncrementPreviewWave()
