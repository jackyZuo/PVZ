@tool
extends TowerDefensePlant

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

func GravebusterOver() -> void :
    explodeComponent.Explode()
    if instance.hypnoses:
        return
    for x in range(gridPos.x - 1, gridPos.x + 2, 1):
        if x < 1 || x > TowerDefenseManager.GetMapGridNum().x:
            continue
        for y in range(gridPos.y - 1, gridPos.y + 2, 1):
            if y < 1 || y > TowerDefenseManager.GetMapGridNum().y:
                continue
            var checkCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(Vector2i(x, y))
            for character: TowerDefenseCharacter in checkCell.characterList:
                if character is TowerDefenseGravestone:
                    character.ExplodeHurt(100000, "Bomb", false)
