class_name TowerDefenseBattleFeaturePortal extends TowerDefenseBattleFeature

const TOWER_DEFENSE_PORTAL = preload("uid://dral054wqsme5")

var portalList: Array[TowerDefensePortal] = []

func ProtalCreate(shape: String, posRange: Vector4i, changeTime: float = 0.0) -> void :
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var portal: TowerDefensePortal = TOWER_DEFENSE_PORTAL.instantiate() as TowerDefensePortal
    characterNode.add_child(portal)
    portal.Init(shape, posRange, changeTime)
    portalList.append(portal)

func ProtalChangePos() -> void :
    for portal: TowerDefensePortal in portalList:
        if is_instance_valid(portal):
            portal.ChangePos()

func GameFail() -> void :
    portalList.clear()

func SyncSerialize() -> Dictionary:
    var portals: Array = []
    for portal in portalList:
        if is_instance_valid(portal):
            portals.append({
                "shape": portal.shape if portal.get("shape") else "", 
                "pos_range_x": portal.posRange.x if portal.get("posRange") else 0, 
                "pos_range_y": portal.posRange.y if portal.get("posRange") else 0, 
                "pos_range_z": portal.posRange.z if portal.get("posRange") else 0, 
                "pos_range_w": portal.posRange.w if portal.get("posRange") else 0, 
                "change_time": portal.changeTime if portal.get("changeTime") else 0.0, 
                "grid_pos1_x": portal.gridPos1.x if portal.get("gridPos1") else 0, 
                "grid_pos1_y": portal.gridPos1.y if portal.get("gridPos1") else 0, 
                "grid_pos2_x": portal.gridPos2.x if portal.get("gridPos2") else 0, 
                "grid_pos2_y": portal.gridPos2.y if portal.get("gridPos2") else 0, 
            })
    return {"portals": portals}

func SyncDeserialize(_data: Dictionary) -> void :
    if MultiPlayerManager.isHost:
        return
    var portals_data: Array = _data.get("portals", [])
    var existing_shapes: Dictionary = {}
    for portal in portalList:
        if is_instance_valid(portal):
            existing_shapes[portal.get_instance_id()] = true
    for portal_data in portals_data:
        if !(portal_data is Dictionary):
            continue
        var shape: String = portal_data.get("shape", "")
        var pos_range_x: int = portal_data.get("pos_range_x", 0)
        var pos_range_y: int = portal_data.get("pos_range_y", 0)
        var pos_range_z: int = portal_data.get("pos_range_z", 0)
        var pos_range_w: int = portal_data.get("pos_range_w", 0)
        var change_time: float = portal_data.get("change_time", 0.0)
        var grid_pos1_x: int = portal_data.get("grid_pos1_x", 0)
        var grid_pos1_y: int = portal_data.get("grid_pos1_y", 0)
        var grid_pos2_x: int = portal_data.get("grid_pos2_x", 0)
        var grid_pos2_y: int = portal_data.get("grid_pos2_y", 0)
        var matched: bool = false
        for portal in portalList:
            if !is_instance_valid(portal):
                continue
            if portal.shape == shape and existing_shapes.has(portal.get_instance_id()):
                portal.gridPos1 = Vector2i(grid_pos1_x, grid_pos1_y)
                portal.gridPos2 = Vector2i(grid_pos2_x, grid_pos2_y)
                var grid_size: Vector2 = TowerDefenseManager.GetMapGridSize()
                portal.protalNode1.global_position = TowerDefenseManager.GetMapCellPlantPos(portal.gridPos1) + Vector2(grid_size.x / 2, 0)
                portal.protalNode2.global_position = TowerDefenseManager.GetMapCellPlantPos(portal.gridPos2) + Vector2(grid_size.x / 2, 0)
                existing_shapes.erase(portal.get_instance_id())
                matched = true
                break
        if !matched:
            var pos_range: Vector4i = Vector4i(pos_range_x, pos_range_y, pos_range_z, pos_range_w)
            ProtalCreate(shape, pos_range, change_time)
            var new_portal: TowerDefensePortal = portalList[portalList.size() - 1]
            if is_instance_valid(new_portal):
                new_portal.gridPos1 = Vector2i(grid_pos1_x, grid_pos1_y)
                new_portal.gridPos2 = Vector2i(grid_pos2_x, grid_pos2_y)
                var grid_size: Vector2 = TowerDefenseManager.GetMapGridSize()
                new_portal.protalNode1.global_position = TowerDefenseManager.GetMapCellPlantPos(new_portal.gridPos1) + Vector2(grid_size.x / 2, 0)
                new_portal.protalNode2.global_position = TowerDefenseManager.GetMapCellPlantPos(new_portal.gridPos2) + Vector2(grid_size.x / 2, 0)

func SaveFeature() -> Dictionary:
    var portals: Array = []
    for portal in portalList:
        if is_instance_valid(portal):
            portals.append({
                "shape": portal.shape, 
                "pos_range_x": portal.posRange.x, 
                "pos_range_y": portal.posRange.y, 
                "pos_range_z": portal.posRange.z, 
                "pos_range_w": portal.posRange.w, 
                "change_time": portal.changeTime, 
                "grid_pos1_x": portal.gridPos1.x, 
                "grid_pos1_y": portal.gridPos1.y, 
                "grid_pos2_x": portal.gridPos2.x, 
                "grid_pos2_y": portal.gridPos2.y, 
            })
    return {"portals": portals}

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    portalList.clear()
    var portalsData: Array = _data.get("portals", [])
    for portalData: Dictionary in portalsData:
        var shape: String = portalData.get("shape", "")
        var posRangeX: int = portalData.get("pos_range_x", 0)
        var posRangeY: int = portalData.get("pos_range_y", 0)
        var posRangeZ: int = portalData.get("pos_range_z", 0)
        var posRangeW: int = portalData.get("pos_range_w", 0)
        var changeTime: float = portalData.get("change_time", 0.0)
        var gridPos1X: int = portalData.get("grid_pos1_x", 0)
        var gridPos1Y: int = portalData.get("grid_pos1_y", 0)
        var gridPos2X: int = portalData.get("grid_pos2_x", 0)
        var gridPos2Y: int = portalData.get("grid_pos2_y", 0)
        var posRange: Vector4i = Vector4i(posRangeX, posRangeY, posRangeZ, posRangeW)
        ProtalCreate(shape, posRange, changeTime)
        var newPortal: TowerDefensePortal = portalList[portalList.size() - 1]
        if is_instance_valid(newPortal):
            newPortal.gridPos1 = Vector2i(gridPos1X, gridPos1Y)
            newPortal.gridPos2 = Vector2i(gridPos2X, gridPos2Y)
            var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
            newPortal.protalNode1.global_position = TowerDefenseManager.GetMapCellPlantPos(newPortal.gridPos1) + Vector2(gridSize.x / 2, 0)
            newPortal.protalNode2.global_position = TowerDefenseManager.GetMapCellPlantPos(newPortal.gridPos2) + Vector2(gridSize.x / 2, 0)
            newPortal.protalSprite1.z_index = 0 + newPortal.gridPos1.y * TowerDefenseEnum.LAYER_GROUNDITEM.MAX
            newPortal.protalSprite2.z_index = 0 + newPortal.gridPos2.y * TowerDefenseEnum.LAYER_GROUNDITEM.MAX
