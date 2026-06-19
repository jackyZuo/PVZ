class_name LightDetectionComponent extends ComponentBase

var parent: TowerDefenseCharacter

func GetName() -> String:
    return "LightDetectionComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func CheckShow() -> bool:
    for i in range(-1, 2, 1):
        for j in range(-1, 2, 1):
            if i == 0 && j == 0:
                continue
            var checkCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(parent.gridPos + Vector2i(i, j))
            if is_instance_valid(checkCell):
                if checkCell.HasLight():
                    return true
    return false
