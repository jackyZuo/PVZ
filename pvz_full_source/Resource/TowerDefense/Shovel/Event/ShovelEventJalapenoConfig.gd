class_name ShovelEventJalapenoConfig extends ShovelEventConfig

@export var destroy: bool = true

func Execute(character: TowerDefenseCharacter) -> void :
    if character.cost > 0:
        TowerDefenseCharacter.CreateJalapenoFire(TowerDefenseEnum.CHARACTER_CAMP.PLANT, character.gridPos, character.cost)
    if destroy:
        character.ShovelDestroy()
