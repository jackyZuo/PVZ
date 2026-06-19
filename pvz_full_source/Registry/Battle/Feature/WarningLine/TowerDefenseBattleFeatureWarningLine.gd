class_name TowerDefenseBattleFeatureWarningLine extends TowerDefenseBattleFeature

const WARNING_LINE = preload("uid://7e2ylijvno4n")

var warningLines: Array[WarningLine] = []

func AddWarningLine(row: int) -> void :
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var warningLine: WarningLine = WARNING_LINE.instantiate()
    characterNode.add_child(warningLine)
    warningLine.global_position = TowerDefenseManager.GetMapCellPos(Vector2i(row + 1, 1)) + Vector2(-10, 0)
    warningLine.sprite.scale.y = (TowerDefenseManager.GetMapGridSize().x * TowerDefenseManager.GetMapGridNum().x - 20) / 502.0
    warningLine.feature = self
    warningLine.row = row
    warningLines.append(warningLine)

func OnWarningLineTriggered() -> void :
    for _character: TowerDefenseCharacter in TowerDefenseManager.GetCharacter():
        _character.process_mode = Node.PROCESS_MODE_DISABLED
    control.GameFail(null)
    control.ZombieWonLevelFail(false)

func SaveFeature() -> Dictionary:
    var rows: Array = []
    for warningLine: WarningLine in warningLines:
        if is_instance_valid(warningLine):
            rows.append(warningLine.row)
    return {"rows": rows}

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    var rows: Array = _data.get("rows", [])
    for row: int in rows:
        AddWarningLine(row)
