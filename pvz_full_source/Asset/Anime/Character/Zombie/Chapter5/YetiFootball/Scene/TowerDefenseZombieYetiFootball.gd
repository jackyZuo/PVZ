@tool
extends TowerDefenseZombie

func _ready() -> void :
    super._ready()
    timeScaleInit = 1.5
    sprite.SetFliters(["anim_face"], false)
    if Engine.is_editor_hint():
        return

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    sprite.timeScale = timeScale * 1.0

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 1.0

func DestroySet() -> void :
    if (Global.isEditor && Global.enterLevelMode == "DiyLevel") || Global.enterLevelMode == "LoadLevel" || Global.enterLevelMode == "OnlineLevel":
        return
    var rand = randf()
    if rand <= 0.02:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_DIAMOND, global_position - Vector2(0, 40), 120, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos = gridPos
    elif rand < 0.2:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_GOLD, global_position - Vector2(0, 40), 120, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos = gridPos
    else:
        var item = TowerDefenseManager.FallingObjectItemCreate(ObjectManagerConfig.OBJECT.COIN_SILVER, global_position - Vector2(0, 40), 120, Vector2(randf_range(-100.0, 100.0), -400.0), 980.0)
        item.gridPos = gridPos
    await get_tree().physics_frame

func GetBuffAdd(key: String) -> void :
    match key:
        "IceSpeedDown", "Forzen":
            timeScaleInit = 3.0
            sprite.SetFliters(["anim_face"], false)
        "RedHeat", "FireHit":
            timeScaleInit = 0.5
            sprite.SetFliters(["anim_face"], true)
