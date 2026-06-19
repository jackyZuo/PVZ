class_name TowerDefenseCharacterBuffNormalHit extends TowerDefenseCharacterBuffConfig

func _init() -> void :
    key = "NormalHit"

func Enter() -> void :
    character.buff.BuffDelete("IceSpeedDown")
    character.buff.BuffDelete("Frozen")
    character.buff.BuffDelete("RedHeat")
    character.buff.BuffDelete("Cherry")
    character.buff.BuffDelete("Poisoning")

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    return true

func Exit() -> void :
    pass

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    pass
