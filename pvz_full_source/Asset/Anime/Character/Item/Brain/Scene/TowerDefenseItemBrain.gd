@tool
extends TowerDefenseItem

signal brainDestroy()

var over: bool = false

func _ready() -> void :
    super._ready()
    add_to_group("Brain")
    targetRegistrationComponent.canProjectileCheck = false

func DestroySet() -> void :
    if over:
        return
    over = true
    brainDestroy.emit()
    if (Global.isEditor && Global.enterLevelMode == "DiyLevel") || Global.enterLevelMode == "LoadLevel" || Global.enterLevelMode == "OnlineLevel":
        return
    var rand = randf()
    if rand <= 0.02:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_DIAMOND, global_position, 70, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos = gridPos
    elif rand < 0.2:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, global_position, 70, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos = gridPos
    else:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, global_position, 70, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos = gridPos
    await get_tree().physics_frame
