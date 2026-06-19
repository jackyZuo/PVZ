class_name TowerDefenseCharacterEventCoinCreate extends TowerDefenseCharacterEventBase

@export var num: float = 10.0
@export var dieCreate: bool = false
@export var collect: bool = false

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, num, dieCreate, collect)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, num * delta, dieCreate, collect)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, num, dieCreate, collect)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    num = valueDictionary.get("Num", 50.0)
    dieCreate = valueDictionary.get("DieCreate", false)

func Export() -> Dictionary:
    return {
        "EventName": "CoinCreate", 
        "Value": {
            "Num": num, 
            "DieCreate": dieCreate
        }
    }

static func Run(target: TowerDefenseCharacter, _num = 10.0, _dieCreate: bool = false, _collect: bool = false) -> void :
    if _dieCreate:
        if !target.IsDie():
            return
    target.CoinCreate(target.global_position, _num, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0, _collect)
