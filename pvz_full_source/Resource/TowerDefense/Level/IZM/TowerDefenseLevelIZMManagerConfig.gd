class_name TowerDefenseLevelIZMManagerConfig extends Resource

@export var shuffle: bool = true

func Init(data: Dictionary) -> void :
    shuffle = data.get("Shuffle", true)

func Export() -> Dictionary:
    var data: Dictionary = {
        "Shuffle": shuffle
    }
    return data
