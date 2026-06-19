@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var collisionShape: CollisionShape2D = %CollisionShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75

func Explode() -> void :
    var characterList = attackComponent.GetCharcterList()
    for character: TowerDefenseCharacter in characterList:
        if character is TowerDefenseZombie:
            if character.instance.hypnoses:
                continue
            character.instance.ArmorClear()
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
                if (character is TowerDefenseGravestone) || (character is TowerDefenseCrater) || (character is TowerDefenseItem && character.config.name == "ItemLadder"):
                    character.Destroy()
    packet.overrideCost = 100
