class_name TowerDefenseCharacterEventGoldShardCreate extends TowerDefenseCharacterEventBase

@export var dieCreate: bool = false
@export var num: int = 0

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, dieCreate, num)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, dieCreate, num)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, dieCreate, num)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    dieCreate = valueDictionary.get("DieCreate", false)
    num = valueDictionary.get("Num", 0)

func Export() -> Dictionary:
    return {
        "EventName": "GoldShardCreate", 
        "Value": {
            "DieCreate": dieCreate, 
            "Num": num
        }
    }

static func Run(target: TowerDefenseCharacter, _dieCreate: bool = false, _num: int = 0) -> void :
    if _dieCreate:
        if !target.IsDie():
            return
    for i in _num:
        target.GoldShardCreate(target.global_position, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
