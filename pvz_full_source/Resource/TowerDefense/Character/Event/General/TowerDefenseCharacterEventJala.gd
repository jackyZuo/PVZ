class_name TowerDefenseCharacterEventJala extends TowerDefenseCharacterEventBase

@export var num: float = 200.0
@export var eventTargetList: Array[TowerDefenseCharacterEventBase]
@export var allEventList: Array[TowerDefenseCharacterEventBase]

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    var camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT
    if target.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
    Run(target, num, camp, eventTargetList, allEventList)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    var camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT
    if target.camp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
        camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
    Run(target, num, camp, eventTargetList, allEventList)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, num, projectile.camp, eventTargetList, allEventList)

static func Run(target: TowerDefenseCharacter, _num: float = 200.0, camp: TowerDefenseEnum.CHARACTER_CAMP = TowerDefenseEnum.CHARACTER_CAMP.PLANT, _eventTargetList: Array[TowerDefenseCharacterEventBase] = [], _allEventList: Array[TowerDefenseCharacterEventBase] = []) -> void :
    TowerDefenseCharacter.CreateJalapenoFire(camp, target.gridPos, _num, _eventTargetList, _allEventList)
