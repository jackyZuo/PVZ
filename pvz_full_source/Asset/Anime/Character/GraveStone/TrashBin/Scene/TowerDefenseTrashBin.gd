@tool
extends TowerDefenseGravestone

var over: bool = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if is_instance_valid(cell) && !nearDie && !die:
        for character in cell.GetCharacterList():
            if character is not TowerDefensePlant:
                continue
            if character is TowerDefensePlantBowlingBase:
                continue
            character.componentAlive = false
            character.invisible = true
            character.instance.canBeCollection = false

func DestroySet() -> void :
    if is_instance_valid(cell):
        for character in cell.GetCharacterList():
            if character is not TowerDefensePlant:
                continue
            if character is TowerDefensePlantBowlingBase:
                continue
            character.componentAlive = true
            character.invisible = false
            character.instance.canBeCollection = true
    super.DestroySet()
