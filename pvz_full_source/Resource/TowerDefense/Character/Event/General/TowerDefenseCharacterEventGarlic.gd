class_name TowerDefenseCharacterEventGarlic extends TowerDefenseCharacterEventBase

@export var fliterCar: bool = true

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, fliterCar)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, fliterCar)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, fliterCar)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    fliterCar = valueDictionary.get("FliterCar", false)

func Export() -> Dictionary:
    return {
        "EventName": "Garlic", 
        "Value": {
            "FliterCar": fliterCar
        }
    }

static func Run(target: TowerDefenseCharacter, _fliterCar: bool = true) -> void :
    if _fliterCar:
        if target.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.CAR:
            return
    target.Garlic()
