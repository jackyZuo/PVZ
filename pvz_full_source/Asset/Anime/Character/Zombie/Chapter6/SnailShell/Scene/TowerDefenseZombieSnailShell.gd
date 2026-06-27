@tool
extends TowerDefenseZombie

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    targetRegistrationComponent.canCarry = false

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if die || nearDie:
        return
    if attackComponent.CanAttack():
        attackComponent.Attack(GetArmorFromName("Shell").hitPoints)
        Die()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Shell":
            Die()

func DieEntered() -> void :
    if !die:
        HitpointsEmpty()
        die = true
    if !nearDie:
        HitpointsNearDie()
        nearDie = true
    if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
        if GameSaveManager.GetFeatureValue("Coins"):
            var item = TowerDefenseManager.FallingObjectCreate(global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            if item:
                item.gridPos = gridPos
    sprite.SetAnimation(dieAnimeClip, false)
