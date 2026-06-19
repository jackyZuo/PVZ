@tool
extends TowerDefensePlantBowlingBase

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent


@warning_ignore("unused_parameter")
func Bowling(character: TowerDefenseCharacter) -> void :
    explodeComponent.Explode()
    Destroy()
