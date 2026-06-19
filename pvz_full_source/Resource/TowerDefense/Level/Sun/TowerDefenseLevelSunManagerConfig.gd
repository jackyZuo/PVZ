class_name TowerDefenseLevelSunManagerConfig extends Resource

@export var open: bool = true
@export var type: String = "Normal"
@export var begin: int = 300
@export var spawnInterval: float = 12.0
@export var spawnNum: int = 50
@export var movingMethod: TowerDefenseEnum.SUN_MOVING_METHOD = TowerDefenseEnum.SUN_MOVING_METHOD.LAND

func Init(sunManagerData: Dictionary) -> void :
    open = sunManagerData.get("Open", true)
    type = sunManagerData.get("Type", "Normal")
    begin = sunManagerData.get("Begin", 300)
    spawnInterval = sunManagerData.get("SpawnInterval", 12.0)
    spawnNum = sunManagerData.get("SpawnNum", 50)
    movingMethod = TowerDefenseEnum.SUN_MOVING_METHOD.get(sunManagerData.get("MovingMethod", "LAND").to_upper())

func Export() -> Dictionary:
    return {
        "Open": open, 
        "Type": type, 
        "Begin": begin, 
        "SpawnInterval": spawnInterval, 
        "SpawnNum": spawnNum, 
        "MovingMethod": TowerDefenseEnum.SUN_MOVING_METHOD.find_key(movingMethod)
    }
