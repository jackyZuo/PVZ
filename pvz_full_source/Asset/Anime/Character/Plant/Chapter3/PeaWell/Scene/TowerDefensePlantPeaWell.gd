@tool
extends TowerDefensePlant

@onready var timerComponent: TimerComponent = %TimerComponent

@export var fireInterval: float = 3.0:
    set(_fireInterval):
        fireInterval = _fireInterval

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName

func Timeout(timerName: String) -> void :
    match timerName:
        "Fire":
            if !sprite.pause && sprite.timeScale > 0:
                for i in 36:
                    var dir: Vector2 = Vector2.from_angle(deg_to_rad(i * 10))
                    var projectile = FireComponent.CreateProjectilePositionByData(self, null, GetGroundHeight(global_position.y) + 10, global_position, dir * 200.0, TowerDefenseProjectileCreateData.new(StringName(projectileName)), -1, camp)
                    projectile.checkAll = true
                    projectile.projectileBodyNode.rotation_degrees = i * 10
            if !TowerDefenseManager.IsIZMMode():
                timerComponent.Run("Fire", fireInterval / timeScaleInit)
            else:
                timerComponent.Run("Fire", fireInterval)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !timerComponent.IsRunning("Fire"):
        if !TowerDefenseManager.IsIZMMode():
            timerComponent.Run("Fire", fireInterval / timeScaleInit)
        else:
            timerComponent.Run("Fire", fireInterval)

func ExportVariantSave() -> Dictionary:
    return {"projectileName": projectileName, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    projectileName = data.get("projectileName", "Pea")
    fireInterval = data.get("fireInterval", 3.0)
