
class_name TowerDefenseCharacterEventLuckyDraw extends TowerDefenseCharacterEventBase

@export var eventList: Array[TowerDefenseCharacterEventLuckyDrawItem] = []

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(pos, target, eventList, null)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(pos, target, eventList, null)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(projectile.global_position, target, eventList, projectile)

static func Run(_pos: Vector2, _target: TowerDefenseCharacter, _eventList: Array[TowerDefenseCharacterEventLuckyDrawItem], _projectile: TowerDefenseProjectile) -> void :
    if _eventList.is_empty():
        return
    var weightTotal: float = 0
    for eventItem in _eventList:
        weightTotal += eventItem.weight
    if weightTotal > 0:
        var r: float = randf() * weightTotal
        for eventItem in _eventList:
            if eventItem.event == null:
                continue
            r -= eventItem.weight
            if r <= 0:
                if is_instance_valid(_projectile):
                    eventItem.event.ExecuteProject(_projectile, _target)
                else:
                    eventItem.event.Execute(_pos, _target)
                return
