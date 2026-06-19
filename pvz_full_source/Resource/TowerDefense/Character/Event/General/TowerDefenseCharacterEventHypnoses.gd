class_name TowerDefenseCharacterEventHypnoses extends TowerDefenseCharacterEventBase

@export var time: float = -1

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, time)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, time)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, time)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    time = valueDictionary.get("Time", -1)

func Export() -> Dictionary:
    return {
        "EventName": "Hypnoses", 
        "Value": {
            "Time": time, 
        }
    }

static func Run(target: TowerDefenseCharacter, _time) -> void :
    target.Hypnoses(_time)
