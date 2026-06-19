class_name GlovePickTool extends PacketPickTool

var gloveFeature: TowerDefenseBattleFeatureGlove

func Init(_mapControl: TowerDefenseMapControl) -> void :
    super.Init(_mapControl)

func SetGloveFeature(_gloveFeature: TowerDefenseBattleFeatureGlove) -> void :
    gloveFeature = _gloveFeature

func IsPicking() -> bool:
    return is_instance_valid(gloveFeature) && gloveFeature.glovePick

func PickTool(open: bool) -> void :
    if is_instance_valid(gloveFeature):
        gloveFeature.PickGlove(open)

func ProcessPick(cell: TowerDefenseCellInstance, gridPos: Vector2i, mousePos: Vector2) -> void :
    if is_instance_valid(gloveFeature):
        gloveFeature.ProcessGlovePick(cell, gridPos, mousePos)

func ToolRelease() -> void :
    if is_instance_valid(gloveFeature):
        gloveFeature.GloveRelease()

func ToolReset() -> void :
    if is_instance_valid(gloveFeature):
        gloveFeature.GloveReset()

func GetMapSprite() -> Node2D:
    if is_instance_valid(gloveFeature) && is_instance_valid(gloveFeature.gloveManager) && is_instance_valid(gloveFeature.gloveManager.mapGloveSprite):
        return gloveFeature.gloveManager.mapGloveSprite
    return null
