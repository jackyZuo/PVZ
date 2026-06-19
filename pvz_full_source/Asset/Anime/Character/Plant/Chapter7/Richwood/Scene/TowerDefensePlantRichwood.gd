@tool
extends TowerDefensePlant

@onready var fireComponent: FireComponent = %FireComponent

@onready var light: PointLight2D = %Light

var projectileList: Array

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")
    if is_instance_valid(hitBox) && hitBox.has_overlapping_areas():
        for area: Area2D in hitBox.get_overlapping_areas():
            AreaEntered(area)

func AreaEntered(area: Area2D) -> void :
    var character = area.get_parent()
    if character is TowerDefenseProjectile:
        if character.over:
            return
        if character.has_meta("richwood_fire"):
            return
        if character.camp != camp:
            return
        if character.config.fireMethodFlags & (TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.CATAPULT | TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK):
            return
        projectileList.append(character.config)
        character.Over()
        if projectileList.size() >= 6:
            var save = projectileList.duplicate(true)
            projectileList.clear()
            Attack(save)


func Attack(_projectileList: Array) -> void :
    var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"Chest")
    projectileData.baseDamage = 200
    var fireProjectile = fireComponent.CreateProjectileByData(0, Vector2(600, 0), projectileData, -1, camp, Vector2.ZERO)
    fireProjectile.projectileBodyNode.scale.x = scale.x
    fireProjectile.gridPos = gridPos
    fireProjectile.metaData = _projectileList
    fireProjectile.set_meta("richwood_fire", true)
