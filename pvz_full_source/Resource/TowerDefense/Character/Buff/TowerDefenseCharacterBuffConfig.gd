class_name TowerDefenseCharacterBuffConfig extends Resource

@export_storage var key: String
@export var refresh: bool = true
@export var canFliter: bool = true

var character: TowerDefenseCharacter

func Enter() -> void :
    pass

@warning_ignore("unused_parameter")
func Step(delta: float) -> bool:
    return true

func Exit() -> void :
    pass

@warning_ignore("unused_parameter")
func Refresh(config: TowerDefenseCharacterBuffConfig) -> void :
    pass

func SetAttackNum(num: float) -> float:
    return num

func Destroy() -> void :
    pass

static func CreateBuffByKey(buffKey: String) -> TowerDefenseCharacterBuffConfig:
    match buffKey:
        "Frozen":
            return TowerDefenseCharacterBuffFrozen.new()
        "Burn":
            return TowerDefenseCharacterBuffBurn.new()
        "Hypnoses":
            return TowerDefenseCharacterBuffHypnoses.new()
        "IceSpeedDown":
            return TowerDefenseCharacterBuffIceSpeedDown.new()
        "Dizziness":
            return TowerDefenseCharacterBuffDizziness.new()
        "Butter":
            return TowerDefenseCharacterBuffButter.new()
        "Cherry":
            return TowerDefenseCharacterBuffCherry.new()
        "Pogo":
            return TowerDefenseCharacterBuffPogo.new()
        "Sleep":
            return TowerDefenseCharacterBuffSleep.new()
        "FireHit":
            return TowerDefenseCharacterBuffFireHit.new()
        "RedHeat":
            return TowerDefenseCharacterBuffRedHeat.new()
        "Poisoning":
            return TowerDefenseCharacterBuffPoisoning.new()
        "Fluorescence":
            return TowerDefenseCharacterBuffFluorescence.new()
        "NormalHit":
            return TowerDefenseCharacterBuffNormalHit.new()
        "Squid":
            return TowerDefenseCharacterBuffSquid.new()
        "TabooBean":
            return TowerDefenseCharacterBuffTabooBean.new()
    return null
