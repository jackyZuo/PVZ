class_name TowerDefenseMowerManager extends Control

var mowerFeature: TowerDefenseBattleFeatureMower

var mowerMovePlantPressed: bool = false
var mowerSpriteList: Array[AdobeAnimateSprite] = [null, null, null]
var mowerSpritePosList: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]

func ProcessMowerInput(cell: TowerDefenseCellInstance, gridPos: Vector2i) -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
    if !mapFeature:
        return
    if Input.is_action_just_pressed("Press"):
        if is_instance_valid(cell) && cell.CanMowerMove():
            if !is_instance_valid(mowerSpriteList[0]):
                mowerSpriteList[0] = TowerDefenseManager.GetCharacterSprite("MowerDefault")
                mowerSpriteList[0].global_position = TowerDefenseManager.GetMapCellPlantPos(gridPos) - Vector2(0, 10)
                mowerSpriteList[0].scale = Vector2.ONE * 1.0
                var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                characterNode.add_child(mowerSpriteList[0])
            var mowerTween = create_tween()
            mowerTween.set_ease(Tween.EASE_OUT)
            mowerTween.set_trans(Tween.TRANS_QUART)
            mowerTween.tween_property(mowerSpriteList[0], "global_position", TowerDefenseManager.GetMapCellPlantPos(gridPos) - Vector2(0, 10), 0.5)
            mowerSpriteList[0].z_index = gridPos.y * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + TowerDefenseEnum.LAYER_GROUNDITEM.GROUNDITEM
            mowerSpritePosList[0] = gridPos
            mowerMovePlantPressed = true
    if Input.is_action_just_released("Press"):
        mowerMovePlantPressed = false

    if mowerMovePlantPressed:
        if is_instance_valid(cell):
            var offset: Vector2i = gridPos - mowerSpritePosList[0]
            if offset != Vector2i.ZERO:
                var beginCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(mowerSpritePosList[0])
                if beginCell.CanMoveToCell(cell):
                    var mowerTween = create_tween()
                    mowerTween.set_ease(Tween.EASE_OUT)
                    mowerTween.set_trans(Tween.TRANS_QUART)
                    mowerTween.tween_property(mowerSpriteList[0], "global_position", TowerDefenseManager.GetMapCellPlantPos(gridPos) - Vector2(0, 10), 0.5)
                    beginCell.MoveToCell(cell)
                    mowerSpritePosList[0] = gridPos
                    mowerSpriteList[0].z_index = gridPos.y * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + TowerDefenseEnum.LAYER_GROUNDITEM.GROUNDITEM
    if is_instance_valid(mowerSpriteList[0]):
        var mowerXAxis: int = 0
        var mowerYAxis: int = 0
        var pressFlag: bool = false
        if mowerSpritePosList[0].y - 1 >= 1 && Input.is_action_just_pressed("P1Up"):
            mowerYAxis -= 1
            pressFlag = true
        if mowerSpritePosList[0].y + 1 <= mapFeature.config.gridNum.y && Input.is_action_just_pressed("P1Down"):
            mowerYAxis += 1
            pressFlag = true
        if mowerSpritePosList[0].x - 1 >= 1 && Input.is_action_just_pressed("P1Left"):
            mowerXAxis -= 1
            pressFlag = true
        if mowerSpritePosList[0].x + 1 <= mapFeature.config.gridNum.x && Input.is_action_just_pressed("P1Right"):
            mowerXAxis += 1
            pressFlag = true
        if pressFlag:
            var mowerOffset: Vector2i = Vector2i(mowerXAxis, mowerYAxis)
            if mowerOffset != Vector2i.ZERO:
                var gridCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(mowerSpritePosList[0])
                var moveCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(mowerSpritePosList[0] + mowerOffset)
                if gridCell.CanMoveToCell(moveCell):
                    var mowerTween = create_tween()
                    mowerTween.set_ease(Tween.EASE_OUT)
                    mowerTween.set_trans(Tween.TRANS_QUART)
                    mowerTween.tween_property(mowerSpriteList[0], "global_position", TowerDefenseManager.GetMapCellPlantPos(mowerSpritePosList[0] + mowerOffset) - Vector2(0, 10), 0.5)
                    gridCell.MoveToCell(moveCell)
                    mowerSpritePosList[0] += mowerOffset
                    mowerSpriteList[0].z_index = mowerSpritePosList[0].y * TowerDefenseEnum.LAYER_GROUNDITEM.MAX + TowerDefenseEnum.LAYER_GROUNDITEM.GROUNDITEM
