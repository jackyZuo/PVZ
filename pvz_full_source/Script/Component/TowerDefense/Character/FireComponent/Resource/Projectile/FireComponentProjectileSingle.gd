@tool
class_name FireComponentProjectileSingle extends FireComponentProjectileResource


@export var projectileData: TowerDefenseProjectileCreateData


var projectileName: String:
    set(value):
        if !projectileData || value != String(projectileData.projectileName):
            projectileData = TowerDefenseProjectileCreateData.new(StringName(value))
    get:
        if projectileData:
            return String(projectileData.projectileName)
        return ""





func CanFire(fireComponent: FireComponent, collisionFlag: int) -> bool:
    if !projectileData:
        return false
    return fireComponent.CanFire(projectileData, collisionFlag)


func GetProjetile() -> TowerDefenseProjectileCreateData:
    return projectileData
