class_name TowerDefenseBattleFeatureFog extends TowerDefenseBattleFeature

const TOWER_DEFENSE_FOG = preload("uid://cu8nc147admpx")

var fogNode: Node2D
var config: TowerDefenseLevelFogManagerConfig
var beginColumn: int = 0
var mapGridNum: Vector2i
var timerList: Array[Timer]
var tweenList: Array[Array]
var fogLine: Array[Array]
var fogNodeInitX: float = 0.0



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseLevelFogManagerConfig.new()
    config.Init(data)
    beginColumn = config.beginColumn
    mapGridNum = TowerDefenseManager.GetMapGridNum()
    fogNode = Node2D.new()
    control.AddNode(fogNode, 1)
    for i in 27:
        var timer = Timer.new()
        timer.one_shot = true
        timer.autostart = false
        timer.wait_time = 15.0
        timer.timeout.connect(FogBack.bind(i))
        timerList.append(timer)
        fogNode.add_child(timer)
    for i in 27:
        fogLine.append([])
        tweenList.append([])
    BattleEventBus.blowAllEffectEmit.connect(BlowAllEffectEmit)
    BattleEventBus.blowLineEffectEmit.connect(BlowLineEffectEmit)

func GameInit() -> void :
    for x in range(beginColumn, mapGridNum.x + 10, 1):
        for y in range(1, mapGridNum.y + 2, 1):
            var pos = TowerDefenseManager.GetMapCellPosCenter(Vector2i(x, y))
            var fog = TOWER_DEFENSE_FOG.instantiate()
            fog.global_position = pos
            fog.gridPos = Vector2i(x, y)
            fog.beginColumn = beginColumn
            fogLine[y].append(fog)
            fogNode.add_child(fog)
            if x > mapGridNum.x + 1:
                fog.area.queue_free()
    var _pos: Vector2 = TowerDefenseManager.GetMapCellPosCenter(Vector2i(beginColumn, 0))
    fogNodeInitX = 1350.0 - _pos.x
    fogNode.global_position.x = fogNodeInitX

func GameInitFromProgress() -> void :
    GameInit()

func GameEntry() -> void :
    for y in range(1, mapGridNum.y + 2, 1):
        for getTween: Tween in tweenList[y]:
            if is_instance_valid(getTween):
                getTween.kill()
        tweenList[y].clear()
        if is_instance_valid(timerList[y]):
            timerList[y].stop()
        for fog in fogLine[y]:
            fog.position = fog.savePos
            if fog.gridPos.x > mapGridNum.x + 1:
                fog.canVisible = false
            else:
                fog.canVisible = true
    if is_instance_valid(fogNode):
        fogNode.global_position.x = fogNodeInitX

func GameReady() -> void :
    for y in range(1, mapGridNum.y + 2, 1):
        for fog in fogLine[y]:
            if fog.gridPos.x > mapGridNum.x + 1:
                fog.canVisible = true

func GameStart() -> void :
    var tween = fogNode.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(fogNode, ^"global_position:x", 0.0, 3.0)

func GameStartFromProgress() -> void :
    if is_instance_valid(fogNode):
        fogNode.global_position.x = 0.0

func SyncSerialize() -> Dictionary:
    var fog_data: Dictionary = {}
    if is_instance_valid(fogNode):
        fog_data["fog_enabled"] = true
        var fog_cells: Array = []
        for line: Array in fogLine:
            for fog_item in line:
                if is_instance_valid(fog_item):
                    fog_cells.append({
                        "grid_x": fog_item.gridPos.x if fog_item.get("gridPos") else 0, 
                        "grid_y": fog_item.gridPos.y if fog_item.get("gridPos") else 0, 
                        "revealed": !fog_item.visible if fog_item.get("visible") != null else false
                    })
        fog_data["fog_cells"] = fog_cells
    return fog_data

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("fog_cells") and is_instance_valid(fogNode):
        var fog_cells: Array = _data["fog_cells"]
        for fog_cell in fog_cells:
            var revealed: bool = fog_cell.get("revealed", false)
            if revealed:
                var grid_x: int = fog_cell.get("grid_x", 0)
                var grid_y: int = fog_cell.get("grid_y", 0)
                for line: Array in fogLine:
                    for fog_item in line:
                        if is_instance_valid(fog_item) and fog_item.get("gridPos"):
                            if fog_item.gridPos.x == grid_x and fog_item.gridPos.y == grid_y:
                                fog_item.visible = false
                                break



func FogBlow(line: int) -> void :
    for getTween: Tween in tweenList[line]:
        if is_instance_valid(getTween):
            getTween.kill()
    tweenList[line].clear()
    for fog in fogLine[line]:
        var tween = fog.create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(fog, ^"global_position:x", fog.savePos.x + 1400, 1.5)
        tweenList[line].append(tween)

func FogBack(line: int) -> void :
    for getTween: Tween in tweenList[line]:
        if is_instance_valid(getTween):
            getTween.kill()
    tweenList[line].clear()
    for fog in fogLine[line]:
        var tween = fog.create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(fog, ^"global_position:x", fog.savePos.x, 3.0)
        tweenList[line].append(tween)

func BlowAllEffectEmit() -> void :
    for y in range(1, mapGridNum.y + 2, 1):
        if is_instance_valid(timerList[y]):
            timerList[y].start(25.0)
        FogBlow(y)

func BlowLineEffectEmit(line: int) -> void :
    if is_instance_valid(timerList[line]):
        timerList[line].start(25.0)
    FogBlow(line)

func SaveFeature() -> Dictionary:
    var timerRemains: Array = []
    for t: Timer in timerList:
        if is_instance_valid(t) and !t.is_stopped():
            timerRemains.append(t.time_left)
        else:
            timerRemains.append(-1.0)
    var fogNodePosX: float = 0.0
    if is_instance_valid(fogNode):
        fogNodePosX = fogNode.global_position.x
    return {
        "timerRemains": timerRemains, 
        "fogNodePosX": fogNodePosX, 
    }

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    var fogNodePosX: float = _data.get("fogNodePosX", 0.0)
    if is_instance_valid(fogNode):
        fogNode.global_position.x = fogNodePosX
    var timerRemains: Array = _data.get("timerRemains", [])
    for i: int in range(min(timerRemains.size(), timerList.size())):
        var remain: float = timerRemains[i]
        if remain >= 0.0 and is_instance_valid(timerList[i]):
            timerList[i].start(remain)
            for fog in fogLine[i]:
                if is_instance_valid(fog):
                    fog.global_position.x = fog.savePos.x + 1400
