class_name TowerDefenseLevelBaseConfig extends Resource

@export var name: String = ""
@export var description: String = "关卡描述"
@export var levelName: String = "关卡名"
@export var levelNumber: int = 1
@export var nextLevel: String = ""
@export var homeWorld: GeneralEnum.HOMEWORLD = GeneralEnum.HOMEWORLD.NOONE

func Init() -> void :
    pass
