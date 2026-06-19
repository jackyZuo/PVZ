class_name TowerDefenseCharacterEventLuckyBagCreate extends TowerDefenseCharacterEventBase

@export var dieCreate: bool = false

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, dieCreate)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, dieCreate)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, dieCreate)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    dieCreate = valueDictionary.get("DieCreate", false)

func Export() -> Dictionary:
    return {
        "EventName": "LuckyBagCreate", 
        "Value": {
            "DieCreate": dieCreate
        }
    }

static func Run(target: TowerDefenseCharacter, _dieCreate: bool = false) -> void :
    if _dieCreate:
        if !target.IsDie():
            return
    target.LuckyBagCreate(target.global_position, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
