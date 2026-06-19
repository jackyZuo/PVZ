class_name TowerDefenseLevelSurvivalZombiePoolRoundAddConfig extends Resource

@export var _round: int = 0
@export var zombieList: Array = []

func Init(data: Dictionary) -> void :
    _round = data.get("Round", 0)
    zombieList = data.get("Zombie", [])

func Export() -> Dictionary:
    return {
        "Round": _round, 
        "Zombie": zombieList
    }
