
class_name FireComponentProjectileWeight extends FireComponentProjectileResource


@export var projectileData: TowerDefenseProjectileCreateData

@export var averageWeight: bool = false

@export var projectileWeight: Array[FireComponentProjectileWeightItem]


var readyProjectile: TowerDefenseProjectileCreateData


var projectileSimilarName: String:
    set(value):
        if value != projectileData.projectileName:
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
    var weightItemList: Array[WeightPickItemBase] = []
    for projectileItem: FireComponentProjectileWeightItem in projectileWeight:
        var item = WeightPickItemBase.new(projectileItem.projectileResource, (projectileItem.weight if !averageWeight else (1.0 / projectileWeight.size())))
        weightItemList.append(item)
    return WeightPickMathine.PickF(weightItemList).item.GetProjetile()


func RefreshProjectile() -> void :
    readyProjectile = GetProjetile()
