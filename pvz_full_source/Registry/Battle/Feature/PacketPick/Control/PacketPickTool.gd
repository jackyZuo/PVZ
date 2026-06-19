class_name PacketPickTool extends Node

var mapControl: TowerDefenseMapControl
var toolPick: bool = false

func Init(_mapControl: TowerDefenseMapControl) -> void :
    mapControl = _mapControl

func IsPicking() -> bool:
    return toolPick

func PickTool(open: bool) -> void :
    toolPick = open

@warning_ignore("unused_parameter")
func ProcessPick(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    pass

func ToolRelease() -> void :
    toolPick = false

func ToolReset() -> void :
    toolPick = false

func GetMapSprite() -> Node2D:
    return null
