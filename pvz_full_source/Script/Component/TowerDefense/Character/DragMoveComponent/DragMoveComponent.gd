
class_name DragMoveComponent extends ComponentBase


var parent: TowerDefenseCharacter


static var currentMoveCharacter: TowerDefenseCharacter


var drag = false


func GetName() -> String:
    return "DragMoveComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return



@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void :
    var gridPos: Vector2i = TowerDefenseManager.GetMapGridPosFromMouse(get_global_mouse_position())

    if Input.is_action_just_pressed("Press"):
        var flag: bool = false
        if gridPos == parent.gridPos:
            flag = true
        if !flag:
            for offset in parent.config.extendGrid:
                if gridPos - offset == parent.gridPos:
                    flag = true
        if flag:
            currentMoveCharacter = parent
            drag = true
    if Input.is_action_just_released("Press"):
        drag = false
        return

    if currentMoveCharacter == parent:
        if drag:
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos)
            if is_instance_valid(cell):
                var offset: Vector2i = gridPos - parent.gridPos
                if offset != Vector2i.ZERO:
                    var beginCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(parent.gridPos)
                    parent.destroy.emit(parent)
                    if cell.CanPacketPlant(parent.packet):
                        beginCell.MoveCharacterToCell(parent, cell)
                    else:
                        beginCell.CharacterPlant(parent.packet, parent)

        var mowerXAxis: int = 0
        var mowerYAxis: int = 0
        var pressFlag: bool = false
        if parent.gridPos.y - 1 >= 1 && Input.is_action_just_pressed("P1Up"):
            mowerYAxis -= 1
            pressFlag = true
        if parent.gridPos.y + 1 <= TowerDefenseManager.GetMapGridNum().y && Input.is_action_just_pressed("P1Down"):
            mowerYAxis += 1
            pressFlag = true
        if parent.gridPos.x - 1 >= 1 && Input.is_action_just_pressed("P1Left"):
            mowerXAxis -= 1
            pressFlag = true
        if parent.gridPos.x + 1 <= TowerDefenseManager.GetMapGridNum().x && Input.is_action_just_pressed("P1Right"):
            mowerXAxis += 1
            pressFlag = true
        if pressFlag:
            var mowerOffset: Vector2i = Vector2i(mowerXAxis, mowerYAxis)
            if mowerOffset != Vector2i.ZERO:
                var gridCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(parent.gridPos)
                var moveCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(parent.gridPos + mowerOffset)
                parent.destroy.emit(parent)
                if moveCell.CanPacketPlant(parent.packet):
                    gridCell.MoveCharacterToCell(parent, moveCell)
                else:
                    gridCell.CharacterPlant(parent.packet, parent)
