@tool
extends TowerDefenseZombie

var halfHp: bool = false
var isAttack: bool = false

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if randf() > 0.5:
        sprite.SetFliter("anim_tongue", true)
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

func AttackEntered():
    super.AttackEntered()
    isAttack = true
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func AttackExited() -> void :
    super.AttackExited()
    isAttack = false
    if HasShield():
        sprite.SetFliters(["Zombie_outerarm_upper", "Zombie_outerarm_hand", "Zombie_outerarm_lower"], false)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            halfHp = true
            sprite.SetFliters(["Zombie_outerarm_upper"], true)

func ArmorDamagePointReach(armorName: String, stage: int) -> void :
    super.ArmorDamagePointReach(armorName, stage)
    if isAttack && HasShield() && stage > 0:
        sprite.SetFliters(["Zombie_outerarm_upper"], true)
        if !halfHp:
            sprite.SetFliters(["Zombie_outerarm_hand", "Zombie_outerarm_lower"], true)

func DieEntered() -> void :
    super.DieEntered()
    DestroySet()

func DestroySet() -> void :
    if over:
        return
    over = true

    var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"HypnoPuff")
    projectileData.baseDamage = 0.0
    projectileData.fireMethodFlags = TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.TRACK
    var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByData(null, null, 0, global_position, Vector2(300 * scale.x, 0), projectileData, -1, camp, Vector2.ZERO)
    projectile.projectileBodyNode.scale.x = spriteGroup.scale.x
    projectile.gridPos = gridPos
