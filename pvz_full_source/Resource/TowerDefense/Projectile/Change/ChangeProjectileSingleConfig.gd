class_name ChangeProjectileSingleConfig extends Resource

@export var projectileData: TowerDefenseProjectileCreateData
@export var projectileConfig: TowerDefenseProjectileConfig
@export var changeAudio: String

var projectileName: String:
    get:
        if projectileData:
            return String(projectileData.projectileName)
        return ""
