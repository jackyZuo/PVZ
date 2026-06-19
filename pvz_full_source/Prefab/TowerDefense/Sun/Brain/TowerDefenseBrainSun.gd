class_name TowerDefenseBrainSun extends TowerDefenseSunBase

func GetGroupName() -> String:
    return "BrainSun"

func GetPoolKey() -> int:
    return ObjectManagerConfig.OBJECT.SUN_BRAIN

func GetCollectValue() -> int:
    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        return sunNum
    return - sunNum

func OnInitScaleTween(tween: Tween) -> void :
    tween.finished.connect(Collection)
