class_name TowerDefenseSunJalapeno extends TowerDefenseSunBase

var gridPos: Vector2i

func GetGroupName() -> String:
    return "JalapenoSun"

func GetPoolKey() -> int:
    return ObjectManagerConfig.OBJECT.SUN_JALAPENO

func OnCollectStart() -> void :
    if gridPos == Vector2i.ZERO:
        gridPos = TowerDefenseManager.GetMapGridPos(sprite.global_position)
    var handler: JalapenoSunDropItemHandler = DropItemRegistry.GetJalapenoSunHandler()
    if handler:
        handler.gridPos = gridPos
    Explode()

func GetCollectValue() -> int:
    return sunNum

func ShouldAutoCollect() -> bool:
    autoCollect = false
    return super.ShouldAutoCollect()

func OnDieDown() -> bool:
    return false

func OnRefresh() -> void :
    gridPos = Vector2.ZERO

func Explode() -> void :
    if sunNum > 0:
        TowerDefenseCharacter.CreateJalapenoFire(TowerDefenseEnum.CHARACTER_CAMP.PLANT, gridPos, sunNum * 10.0)
    else:
        TowerDefenseCharacter.CreateJalapenoFire(TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE, gridPos, - sunNum * 10.0)
