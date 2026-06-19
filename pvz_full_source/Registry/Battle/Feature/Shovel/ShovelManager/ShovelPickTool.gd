class_name ShovelPickTool extends PacketPickTool

var shovelManager: ShovelManager

func Init(_mapControl: TowerDefenseMapControl) -> void :
    super.Init(_mapControl)

func SetShovelManager(_shovelManager: ShovelManager) -> void :
    shovelManager = _shovelManager

func IsPicking() -> bool:
    return is_instance_valid(shovelManager) && shovelManager.shovelPick

func PickTool(open: bool) -> void :
    if is_instance_valid(shovelManager):
        shovelManager.PickShovel(open)

func ProcessPick(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    if is_instance_valid(shovelManager):
        shovelManager.ProcessShovelPick(cell, gridPos, mousePos)

func ToolRelease() -> void :
    if is_instance_valid(shovelManager):
        shovelManager.ShovelRelease()

func ToolReset() -> void :
    if is_instance_valid(shovelManager):
        shovelManager.ShovelReset()

func GetMapSprite() -> Node2D:
    if is_instance_valid(shovelManager) && is_instance_valid(shovelManager.mapShovelSprite):
        return shovelManager.mapShovelSprite
    return null
