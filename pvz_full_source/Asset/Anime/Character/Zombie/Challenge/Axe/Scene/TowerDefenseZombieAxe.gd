@tool
extends TowerDefenseZombie

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 3.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Axe":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

var hasAxe: bool = true:
    set(_hasAxe):
        hasAxe = _hasAxe
        if !hasAxe:
            instance.ArmorDelete("Axe")
            useAttackDps = true
            attackComponent.attackType = "Eat"
            attackAnimeClip = "Eat"
            attackWaterAnimeClip = "WaterEat"

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func ThrowEntered() -> void :
    if inWater:
        sprite.SetAnimation("WaterFire", false, 0.2)
    else:
        sprite.SetAnimation("Fire", false, 0.2)

@warning_ignore("unused_parameter")
func ThrowProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func ThrowExited() -> void :
    pass

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Axe":
            hasAxe = false

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            if hasAxe:
                state.send_event("ToThrow")

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "WaterFire", "Fire":
            hasAxe = false
            Walk()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "fire":
            if hasAxe:
                var projectile: TowerDefenseProjectile = fireComponent.CreateProjectileByData(0, Vector2(-500, 0), fireComponent.fireCheckList[0].projectile.GetProjetile(), -1, camp, Vector2.ZERO)
                projectile.projectileBodyNode.scale.x = scale.x
                projectile.gridPos = gridPos
        "attack":
            if is_instance_valid(attackComponent.target):
                if attackComponent.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
                    attackComponent.Attack(config.smashAttack * 2.0)
                else:
                    attackComponent.Attack(config.smashAttack)

func ExportVariantSave() -> Dictionary:
    return {
        "hasAxe": hasAxe, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    hasAxe = data.get("hasAxe", true)
